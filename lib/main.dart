import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsListScreen(),
    );
  }
}

class NewsListScreen extends StatefulWidget {
  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<Article> articles = [];
  List<Article> filteredArticles = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    setState(() {
      isLoading = true;
    });
    final apiKey = '7845b90dda89464dbd75c28890a994dd';
    final apiUrl = 'https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'ok') {
        setState(() {
          articles = (responseData['articles'] as List)
              .map((articleData) => Article.fromJson(articleData))
              .toList();
          filteredArticles = List.from(articles);
        });
      } else {
        // Handle error when API response status is not OK
        print('API error: ${responseData['message']}');
      }
    } catch (error) {
      // Handle HTTP error
      print('HTTP error: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterArticles(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredArticles = List.from(articles);
      });
      return;
    }
    setState(() {
      filteredArticles = articles.where((article) {
        return article.title.toLowerCase().contains(query.toLowerCase()) ||
            article.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void sortArticles(String? category) {
    if (category == null) return;
    if (category == 'Mới nhất') {
      filteredArticles.sort((a, b) => b.title.compareTo(a.title));
    } else if (category == 'Phổ biến nhất') {
      filteredArticles.sort((a, b) => b.description.length.compareTo(a.description.length));
    }
    // Add more sorting logic for different categories if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Reader'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Choose Category'),
                    content: DropdownButton<String>(
                      value: selectedCategory,
                      items: <String>['Mới nhất', 'Phổ biến nhất'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                          sortArticles(selectedCategory);
                        });
                      },
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.sort),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterArticles,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredArticles.length,
                    itemBuilder: (ctx, index) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: filteredArticles[index]),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.all(8),
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (filteredArticles[index].urlToImage != null)
                                Image.network(
                                  filteredArticles[index].urlToImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              SizedBox(height: 8),
                              Text(
                                filteredArticles[index].title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                filteredArticles[index].description,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  ArticleDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null)
              Image.network(
                article.urlToImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            Text(
              article.description,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> savedArticles = prefs.getStringList('savedArticles') ?? [];
                savedArticles.add(json.encode(article.toJson()));
                await prefs.setStringList('savedArticles', savedArticles);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Article saved!')),
               
                );
              },
              child: Text('Save Article'),
            ),
          ],
        ),
      ),
    );
  }
}

class Article {
  final String title;
  final String description;
  final String? urlToImage;

  Article({required this.title, required this.description, this.urlToImage});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      urlToImage: json['urlToImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
    };
  }
}
