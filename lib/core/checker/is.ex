defprotocol Argx.Checker.Is do
  def in_range?(term, range)
  def empty?(term)
end

defimpl Argx.Checker.Is, for: Integer do
  def in_range?(term, [l, r]), do: (term >= l and term <= r) or (term == l and term == r)

  def empty?(0), do: true
  def empty?(_other), do: false
end

defimpl Argx.Checker.Is, for: Float do
  def in_range?(term, [l, r]), do: (term >= l and term <= r) or (term == l and term == r)

  def empty?(0.0), do: true
  def empty?(_other), do: false
end

defimpl Argx.Checker.Is, for: BitString do
  def in_range?(term, [l, r]) do
    with len <- String.length(term) do
      (len >= l and len <= r) or (len == l and len == r)
    end
  end

  def empty?(""), do: true
  def empty?(_other), do: false
end

defimpl Argx.Checker.Is, for: List do
  def in_range?(term, [l, r]) do
    with len <- length(term) do
      (len >= l and len <= r) or (len == l and len == r)
    end
  end

  def empty?([]), do: true
  def empty?(_other), do: false
end

defimpl Argx.Checker.Is, for: Map do
  def in_range?(term, [l, r]) do
    with len <- map_size(term) do
      (len >= l and len <= r) or (len == l and len == r)
    end
  end

  def empty?(%{} = term), do: Enum.empty?(term)
  def empty?(_other), do: false
end

defimpl Argx.Checker.Is, for: Atom do
  def in_range?(term, _range), do: is_boolean(term)

  def empty?(_term), do: false
end

defimpl Argx.Checker.Is, for: Any do
  def in_range?(_term, _range), do: false

  def empty?(_term), do: false
end