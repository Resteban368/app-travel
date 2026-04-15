class PagedResult<T> {
  final List<T> data;
  final int total;
  final int totalPages;
  final int page;
  final int limit;

  const PagedResult({
    required this.data,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.limit,
  });
}
