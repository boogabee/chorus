class LicensesController < ApplicationController
  def show
    present License.instance
  end
end
