import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteButton extends StatefulWidget {
  final String chargerId;
  final bool initialFavorite;
  final double iconSize;

  const FavoriteButton({
    super.key,
    required this.chargerId,
    required this.initialFavorite,
    this.iconSize = 30.0,
  });

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool isFavorite;
  late bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.initialFavorite;
    _refreshFavoriteStatus();
  }

  Future<void> _refreshFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    setState(() {
      isLoggedIn = accessToken != null;
    });

    if (isLoggedIn) {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/favorites'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> favorites = json.decode(response.body);
        final favoriteIds =
            favorites.map((favorite) => favorite['charger_id'].toString());
        setState(() {
          isFavorite = favoriteIds.contains(widget.chargerId);
        });
      }
    } else {
      setState(() {
        isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first')),
      );
      return;
    }

    if (isFavorite) {
      await _removeFromFavorites(widget.chargerId);
    } else {
      await _addToFavorites(widget.chargerId);
    }
    _refreshFavoriteStatus();
  }

  Future<void> _addToFavorites(String chargerId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'charger_id': chargerId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Charger added to favorites')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites')),
      );
    }
  }

  Future<void> _removeFromFavorites(String chargerId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/api/favorites/$chargerId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Charger removed from favorites')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
      ),
      color: isLoggedIn ? Colors.red : Colors.grey,
      iconSize: widget.iconSize,
    );
  }
}
