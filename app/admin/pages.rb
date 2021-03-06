# coding: utf-8
ActiveAdmin.register Page do
  menu :priority => 7, :label => 'Stránky'

  filter :title
  filter :created_at

  index do
    column :title do |page|
      link_to page.title, "/#{page.url}"
    end

    actions
  end

  form :partial => 'form'

  show do
    panel 'Detaily' do
      attributes_table_for page do
        row('Titulek') {
          if page.url
            link_to page.title, "/#{page.url}"
          else
            page.title
          end
        }
        row('Tělo stránky') { page.body.html_safe }
      end
    end
    active_admin_comments
  end

end
