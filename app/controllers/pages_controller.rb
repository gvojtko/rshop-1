# coding: utf-8
class PagesController < ApplicationController

  before_filter :set_order, :except => [:sitemap]

  def show
    @page = Page.find_by_url params[:page_url]
    if @page
      @title = @page.title
      @meta_desc = shorten @page.body, 11
    else
      redirect_to '/404.html'
    end
  end

  def contact
    @contact_text = Page.contact_text
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

  def sitemap
    @index = root_url.chomp('/')
    @pages = Page.all
    @products = Product.active
    @categories = Category.all
    render :layout => false
  end

protected

  def contact_form_data_valid?
    return false if params[:phone]!~/^[+0-9 ]{5,20}$/i
    return false if params[:email]!~/^(|([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,}))$/i
    return true
  end

end
