# coding: utf-8
class PagesController < ApplicationController

  def show
    @page = Page.find_by_url params[:page_url]
    if @page
      right_side_content  
      @title = @page.title
      @meta_desc = @page.text 
    else
      redirect_to '/404.html'       
    end
  end

  def contact
    flash[:params]||={}
    if request.post?
      if contact_form_data_valid?
        ContactMailer.question(params).deliver
        flash[:success] = 'Vše bylo úspěšně odesláno'
      else
        flash[:error] = 'Odeslání nebylo úspěšné'
        flash[:params] = params
      end
      redirect_to :action => :contact
    end
  end

protected
  
  def contact_form_data_valid?
    return false if params[:phone]!~/^[+0-9 ]{5,20}$/i
    return false if params[:email]!~/^(|([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}))$/i
    return true
  end

end