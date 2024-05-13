module TranspiledMethods
  def self.f_at_least( value, *args)
    (value < args[0]) ? args[0] : value
  end

  def self.f_at_most( value, *args)
    (value < args[0]) ? value : args[0]
  end

  def self.f_divided_by( value, *args)
    if args[0].is_a?( Integer)
      (value / args[0]).floor
    else
      value / args[0]
    end
  end

  def self.f_floor( value)
    if value.is_a?( String)
      value = value.to_f
    end
    value.floor
  end

  def self.f_split( value, *args)
    value.split( args[0])
  end

  def self.f_times( value, *args)
    value * args[0]
  end

  def self.x( context, *args)
    args.each do |arg|
      if context.is_a?( Hash)
        context = context[arg]
      else
        context = context.send( arg.to_sym)
      end
    end
    context
  end
end
