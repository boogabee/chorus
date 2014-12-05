class TagsController < ApplicationController
  def index
    tags = params[:q].present? ? Tag.named_like(params[:q]) : Tag.all
    present paginate(tags.sort_by!{ |tag| tag.name.downcase })
  end

  def update
    tag = Tag.find(params[:id])
    tag.name = params[:tag][:name]
    tag.save!

    present tag
  end

  def destroy
    tag = Tag.find(params[:id])
    authorize! :destroy, tag
    tag.destroy

    head :ok
  end
end
