module BookMethods
  extend ActiveSupport::Concern

  def borrowed_copies
    object.borrowed_copies
  end

  def available?
    object.available?
  end
end 