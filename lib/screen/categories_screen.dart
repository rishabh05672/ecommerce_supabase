import 'package:ecommerce_supabse/model/category_model.dart';
import 'package:ecommerce_supabse/provider/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                FloatingActionButton(
                  onPressed: () => _navigateToAddCategory(context),
                  mini: true,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (categoryProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${categoryProvider.errorMessage}'),
                        ElevatedButton(
                          onPressed: () => categoryProvider.fetchCategories(),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final categories = categoryProvider.categories;

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No categories found'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _navigateToAddCategory(context),
                          child: Text('Add First Category'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => categoryProvider.fetchCategories(),
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(context, category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: category.imageUrl != null
            ? Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(category.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: Colors.grey),
              ),
        title: Text(
          category.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description?.isNotEmpty ?? false)
              Text(category.description!),
            if (!category.isActive)
              Text('Inactive', style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, category),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: category.isActive ? 'deactivate' : 'activate',
              child: Text(category.isActive ? 'Deactivate' : 'Activate'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Category category,
  ) {
    switch (action) {
      case 'activate':
      case 'deactivate':
        _toggleCategoryStatus(context, category);
        break;
      case 'delete':
        _showDeleteConfirmation(context, category);
        break;
    }
  }

  void _toggleCategoryStatus(BuildContext context, Category category) {
    final updatedCategory = category.copyWith(isActive: !category.isActive);
    context.read<CategoryProvider>().updateCategory(updatedCategory);
  }

  void _showDeleteConfirmation(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<CategoryProvider>()
                  .deleteCategory(category.id);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Category deleted' : 'Failed to delete category',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCategoryScreen()),
    );
  }
}
