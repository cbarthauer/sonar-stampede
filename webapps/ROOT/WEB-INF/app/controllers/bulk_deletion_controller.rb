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
class BulkDeletionController < ApplicationController

  SECTION=Navigation::SECTION_CONFIGURATION

  before_filter :admin_required
  verify :method => :post, :only => [:delete_resources], :redirect_to => { :action => :index }

  def index
    deletion_manager = ResourceDeletionManager.instance
    
    if deletion_manager.currently_deleting_resources? || 
      (!deletion_manager.currently_deleting_resources? && deletion_manager.deletion_failures_occured?)
      # a mass deletion is happening or it has just finished with errors => display the message from the Resource Deletion Manager
      @deletion_manager = deletion_manager
      render :template => 'bulk_deletion/pending_deletions'
    else      
      @tabs = Java::OrgSonarServerUi::JRubyFacade.getInstance().getQualifiersWithProperty('deletable')
      
      @selected_tab = params[:resource_type]
      @selected_tab = 'TRK' unless @tabs.include?(@selected_tab)
      
      # Search for resources
      conditions = "qualifier=:qualifier"
      values = {:qualifier => @selected_tab}
      if params[:name_filter]
        conditions += " AND kee LIKE :kee"
        values[:kee] = '%' + params[:name_filter].strip.downcase + '%'
      end
      
      resource_ids = ResourceIndex.find(:all,
                                        :select => 'resource_id',
                                        :conditions => [conditions, values],
                                        :order => 'name_size').map {|rid| rid.resource_id}.uniq
      
      @resources = Project.find(:all, :conditions => ['id in (?) and enabled=?', resource_ids, true], :order => 'name ASC')
    end
  end
  
  def delete_resources
    resource_to_delete = params[:resources] || []
    resource_to_delete = params[:all_resources].split(',') if params[:all_resources] && !params[:all_resources].blank?
    
    # Ask the resource deletion manager to start the migration
    # => this is an asynchronous AJAX call
    ResourceDeletionManager.instance.delete_resources(resource_to_delete)
    
    # and return some text that will actually never be displayed
    render :text => ResourceDeletionManager.instance.message
  end

  def pending_deletions
    deletion_manager = ResourceDeletionManager.instance
    
    if deletion_manager.currently_deleting_resources? || 
      (!deletion_manager.currently_deleting_resources? && deletion_manager.deletion_failures_occured?)
      # display the same page again and again
      # => implicit render "pending_deletions.html.erb"
    else
      redirect_to :action => 'index'
    end
  end
  
  def dismiss_message
    # It is important to reinit the ResourceDeletionManager so that the deletion screens can be available again
    ResourceDeletionManager.instance.reinit
    
    redirect_to :action => 'index'
  end

end
