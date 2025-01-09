import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //! AppBar
          Container(
            width: double.infinity,
            color: Color.fromARGB(255, 0, 191, 108),
            child: Column(
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Calls",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          //! User Chat List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.only(top: 2, bottom: 10, left: 12, right: 10),
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                          fit: BoxFit.fitHeight,
                          width: 55,
                          height: 55,
                          imageUrl: "https://lh3.googleusercontent.com/a/ACg8ocIyALSQ9RxFBgY_vFTHaHT5LxFQYeGVEQzaGa_kpE_ntzhUZzU=s96-c",
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                      //! If User online then
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 0, 191, 108),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text("Kamesh Singh"),
                  subtitle: Row(
                    children: [
                      Icon(
                        Icons.arrow_outward_sharp,
                        color: Color.fromARGB(255, 0, 191, 108),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "3m ago",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 116, 114, 114),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.videocam_sharp,
                      color: Color.fromARGB(255, 0, 191, 108),
                      size: 26,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
