class String

  # Colors

  def blue
    "\e[1;34m#{self}\e[0m"
  end

  def green
    "\e[1;32m#{self}\e[0m"
  end

  def red
    "\e[1;31m#{self}\e[0m"
  end

  def yellow
    "\e[1;33m#{self}\e[0m"
  end
end