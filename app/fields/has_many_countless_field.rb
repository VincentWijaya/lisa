require "administrate/field/has_many"

# Administrate HasMany field that skips COUNT(*) queries by using
# Kaminari's without_count pagination. Shows Previous/Next controls
# instead of page numbers.
class HasManyCountlessField < Administrate::Field::HasMany
  def resources(page = 1, order = self.order)
    result = order.apply(data)
    result = result.page(page).per(limit).without_count if paginate?
    includes.any? ? result.includes(*includes) : result
  end

  # Avoid data.size which fires SELECT COUNT(*).
  # Always show pagination controls when paginate? is true.
  def more_than_limit?
    paginate?
  end
end
