# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
	
	def clear(tag = :div, classes = 'clear')
    	content_tag(tag, nil, :class => classes)
	end
	
	def menu(items, html_options = {:id => 'menu'})
	    items.map!{|item| content_tag(:li, link_to(item[0], item[1]) + content_tag(:span), :class => current_page?(item[1]) && 'current' || item[2] )  }
	    content_tag(:ul, items * '', html_options)
	end

  # Get the sort criteria for a specific column
  def get_column_sort_criteria(column)
    (params[:sort] == column) ? "#{column}_reverse" : column
  end

  # Get column class based on the sort criteria
  def get_column_class(column)
    case params[:sort] 
    when column              then 'asc'
    when "#{column}_reverse" then 'desc'
    else nil
    end
  end

  def no_content(text="No content", tag = :div, classes = 'no_content has_radius')
    content_tag(tag, text, :class => classes)
  end

  def get_visibility(record, visibility)
    visibility ||= 'private'
    visibility = 'public' if record.is_public
    visibility = 'share' if record.accesses.size > 1
    visibility
  end
  
  def get_item_visibility(record)
    visibility = 'private'
    visibility = record.accesses.collect{|access| link_to(access.group.name, access.group) unless access.group.is_default}.compact.join(', ') if record.accesses.size > 1
    visibility = 'public' if record.is_public
    visibility
  end
  
  def get_groups(record, groups)
    groups ||= []
    groups = record.accesses.collect{|access| access.group_id.to_s} if groups.blank? and record.accesses.size > 1
    groups
  end
end
