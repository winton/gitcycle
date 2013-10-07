class String

  # Colors

  def blue
    color(:blue)
  end

  def green
    color(:green)
  end

  def red
    color(:red)
  end

  def yellow
    color(:yellow)
  end

  # Spacing

  def space(last=false)
    "\n#{self}#{"\n" if last}"
  end
end