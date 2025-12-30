import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import 'add_category_screen.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('manageCategories', lang)), 
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          
          if (categories.isEmpty) {
             return const Center(child: Text('No categories'));
          }

          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cat.color.withValues(alpha: 0.2),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditCategoryScreen(category: cat)
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                           // Confirm Delete
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               title: Text(AppStrings.get('delete', lang)),
                               content: Text(AppStrings.get('confirmDelete', lang)),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.get('cancel', lang))),
                                 TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.get('delete', lang), style: const TextStyle(color: Colors.red))),
                               ],
                             ),
                           );
                           
                           if (confirm == true) {
                             await provider.deleteCategory(cat.id);
                           }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
