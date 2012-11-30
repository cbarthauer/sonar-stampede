#
# Sonar, entreprise quality control tool.
# Copyright (C) 2008-2012 SonarSource
# mailto:contact AT sonarsource DOT com
#
# Sonar is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# Sonar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Sonar; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02
#
class SettingsController < ApplicationController

  SECTION=Navigation::SECTION_CONFIGURATION

  SPECIAL_CATEGORIES=%w(email encryption server_id)

  verify :method => :post, :only => %w(update), :redirect_to => {:action => :index}
  before_filter :admin_required, :only => %w(index)

  def index
    load_properties()
  end

  def update
    resource_id = params[:resource_id]
    @resource = Project.by_key(resource_id) if resource_id

    access_denied if (@resource && !is_admin?(@resource))
    access_denied if (@resource.nil? && !is_admin?)

    load_properties()

    @updated_properties = {}
    update_properties(resource_id)
    update_property_sets(resource_id)

    render :partial => 'settings/properties'
  end

  private

  def update_properties(resource_id)
    (params[:settings] || []).each do |key, value|
      update_property(key, value, resource_id)
    end
  end

  def update_property_sets(resource_id)
    (params[:property_sets] || []).each do |key, set_keys|
      update_property_set(key, set_keys, params[key], resource_id, params[:auto_generate] && params[:auto_generate][key])
    end
  end

  def update_property_set(key, set_keys, fields_hash, resource_id, auto_generate)
    set_keys = Array.new(set_keys.size) { |i| i.to_s } if auto_generate

    set_key_values = {}
    fields_hash.each do |field_key, field_values|
      field_values.zip(set_keys).each do |field_value, set_key|
        set_key_values[set_key] ||= {}
        set_key_values[set_key][field_key] = field_value
      end
    end

    set_keys.reject! { |set_key| set_key.blank? || (auto_generate && set_key_values[set_key].values.all?(&:blank?)) }

    Property.transaction do
      Property.with_key_prefix(key + '.').with_resource(resource_id).delete_all

      update_property(key, set_keys, resource_id)
      set_keys.each do |set_key|
        update_property("#{key}.#{set_key}.key", set_key, resource_id) unless auto_generate

        set_key_values[set_key].each do |field, value|
          update_property("#{key}.#{set_key}.#{field}", value, resource_id)
        end
      end
    end
  end

  def update_property(key, value, resource_id)
    @updated_properties[key] = Property.set(key, value, resource_id)
  end

  def load_properties
    @category = params[:category] || 'general'

    if @resource.nil?
      definitions_per_category = java_facade.propertyDefinitions.globalPropertiesByCategory
    elsif @resource.project?
      definitions_per_category = java_facade.propertyDefinitions.projectPropertiesByCategory
    elsif @resource.module?
      definitions_per_category = java_facade.propertyDefinitions.modulePropertiesByCategory
    end

    @categories = definitions_per_category.keys + SPECIAL_CATEGORIES
    @definitions = definitions_per_category[@category] || []

    not_found('category') unless @categories.include? @category
  end
end
