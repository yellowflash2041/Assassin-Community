module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    def index
      @pages = Page.all
      @code_of_conduct = Page.find_by(slug: "code-of-conduct")
      @privacy = Page.find_by(slug: "privacy")
      @terms = Page.find_by(slug: "terms")
    end

    def new
      if params[:slug]
        prepopulate_new_form params[:slug]
      else
        @page = Page.new
      end
    end

    def edit
      @page = Page.find(params[:id])
    end

    def update
      @page = Page.find(params[:id])
      @page.assign_attributes(page_params)
      if @page.valid?
        @page.update!(page_params)
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :edit
      end
    end

    def create
      @page = Page.new(page_params)
      if @page.valid?
        @page.save!
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :new
      end
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy
      redirect_to "/admin/pages"
    end

    private

    def page_params
      allowed_params = %i[title slug body_markdown body_html body_json description template is_top_level_path
                          social_image]
      params.require(:page).permit(allowed_params)
    end

    def prepopulate_new_form(slug)
      html = view_context.render partial: "pages/coc_text",
                                 locals: {
                                   community_name: view_context.community_name,
                                   email_link: view_context.email_link
                                 }
      @page = case slug
              when "code-of-conduct"
                Page.new(
                  slug: params[:slug],
                  body_html: html,
                  title: "Code of Conduct",
                  description: "A page that describes how to behave on this platform",
                  is_top_level_path: true,
                )
              when "privacy"
                Page.new(
                  slug: params[:slug],
                  body_html: html,
                  title: "Privacy Policy",
                  description: "A page that describes the privacy policy",
                  is_top_level_path: true,
                )
              when "terms"
                Page.new(
                  slug: params[:slug],
                  body_html: html,
                  title: "Terms of Use",
                  description: "A page that describes the terms of use for the application",
                  is_top_level_path: true,
                )
              else
                Page.new
              end
    end
  end
end
