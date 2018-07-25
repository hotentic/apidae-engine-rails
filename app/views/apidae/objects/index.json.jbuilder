json.results do
  json.array!(@objects) do |obj|
    json.id obj.id
    json.title obj.title
  end
end
