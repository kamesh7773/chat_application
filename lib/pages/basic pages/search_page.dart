import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final String heading;
  const SearchPage({super.key, required this.heading});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Border Style
  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(50),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //! AppBar
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 0, 191, 108),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          //! Navigate user to Home Page.
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.heading,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 114, 111, 111),
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: borderStyle,
                      focusedBorder: borderStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          //! User Chat List
          const Padding(
            padding: EdgeInsets.only(left: 18, top: 20, bottom: 10),
            child: Text(
              "Suggested",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 145, 141, 141),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: 6,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: CachedNetworkImage(
                      fit: BoxFit.fitHeight,
                      width: 46,
                      height: 46,
                      imageUrl: "https://lh3.googleusercontent.com/a/ACg8ocIyALSQ9RxFBgY_vFTHaHT5LxFQYeGVEQzaGa_kpE_ntzhUZzU=s96-c",
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  title: const Text("Kamesh Singh"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
