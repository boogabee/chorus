class RunWorkFlowTaskPresenter < JobTaskPresenter
  def to_hash
    super.merge work_flow
  end

  private

  def work_flow
    {
        :work_flow => present(model.payload)
    }
  end
end