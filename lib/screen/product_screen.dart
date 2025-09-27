import 'package:ecommerce_supabse/model/product_model.dart';
import 'package:ecommerce_supabse/provider/category_provider.dart';
import 'package:ecommerce_supabse/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (productProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${productProvider.errorMessage}'),
                      ElevatedButton(
                        onPressed: () => productProvider.fetchProducts(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final products = productProvider.products;

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No products found'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _navigateToAddProduct(),
                        child: Text('Add First Product'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => productProvider.fetchProducts(),
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductProvider>().searchProducts(
                                '',
                              );
                            },
                          )
                        : null,
                  ),
                  onChanged: (query) {
                    context.read<ProductProvider>().searchProducts(query);
                  },
                ),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _navigateToAddProduct,
                mini: true,
                child: Icon(Icons.add),
              ),
            ],
          ),
          SizedBox(height: 8),
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              return Row(
                children: [
                  Text('Filter: '),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: context
                          .watch<ProductProvider>()
                          .selectedCategoryFilter,
                      onChanged: (String? categoryId) {
                        if (categoryId != null) {
                          context.read<ProductProvider>().filterByCategory(
                            categoryId,
                          );
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Categories'),
                        ),
                        ...categoryProvider.categories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: product.images.isNotEmpty
            ? Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(product.images.first),
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
                child: Icon(Icons.image, color: Colors.grey),
              ),
        title: Text(
          product.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stockQuantity}'),
            if (!product.isActive)
              Text('Inactive', style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, product),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: product.isActive ? 'deactivate' : 'activate',
              child: Text(product.isActive ? 'Deactivate' : 'Activate'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => _navigateToEditProduct(product),
      ),
    );
  }

  void _handleMenuAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _navigateToEditProduct(product);
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  void _toggleProductStatus(Product product) {
    final updatedProduct = product.copyWith(isActive: !product.isActive);
    context.read<ProductProvider>().updateProduct(updatedProduct);
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductProvider>().deleteProduct(product.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Product deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductScreen()),
    );
  }

  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
  }
}
