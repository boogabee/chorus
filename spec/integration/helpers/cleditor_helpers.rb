module CleditorHelpers
  def set_cleditor_value(name, value)
    page.should have_selector("textarea[name=#{name}]")
    page.execute_script("$('textarea[name=#{name}]').val('#{value}');")
    page.execute_script("$('textarea[name=#{name}]').cleditor()[0].updateFrame();")
  end
end
