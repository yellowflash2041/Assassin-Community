class Internal::ReactionsController < Internal::ApplicationController
  def update
    @reaction = Reaction.find(params[:id])
    @reaction.update(status: params[:reaction][:status])
    redirect_to "/internal/reports"
  end
end
