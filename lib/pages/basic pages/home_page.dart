import 'package:cached_network_image/cached_network_image.dart';
import '../../services/message_encrption_service.dart';
import '../../providers/last_message_provider.dart';
import '../../utils/date_time_calculator_for_users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_firestore_methods.dart';
import '../../utils/date_time_calculator_for_unseenmsg.dart';
import '../../routes/rotues_names.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFireStoreMethods _firebaseFireStoreMethods = FirebaseFireStoreMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //! AppBar
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 0, 191, 108),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Chats",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        //! Navigate user to Search Page
                        Navigator.of(context).pushNamed(
                          RoutesNames.searchPage,
                          arguments: "Chats",
                        );
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      ActionChip(
                        onPressed: () {
                          //* Hello my name is kamesh
                          // MessageEncrptionService().generateKeys();
                          // MessageEncrptionService().returnKeys();
                          // MessageEncrptionService().encryptMessage(message: "Hello");
                          MessageEncrptionService().encryptionDecryption(
                            message: "Hello",
                            recipientPrivateKey:
                                "-----BEGIN RSA PRIVATE KEY-----MIIFoQIBAAKCAQEAi0H4VCFY/juThqE9X5rc2PI3/Fu41vIqel7DkHekx/fpUyeE1tCpvZMpKmripojA5gp9lZ1BRGmTVo9OnZ2XN/e/xMRjoPdivc4k7DnfA5lCnlinpKiksBr+0I/9SmteylXwF0CAJenflr4uHo7oDasjqB48QUaSl1TYLdnxyS/i8wDhMj+l1P5nwJp8t07aCyOCN/wy41h2iS57NmRN37dXf55F+dki0komhKc0DOaeB8kP3Oi12vcoQHLgtIoa7Dn4VldoTaw/8qA9Wgal2gMAfAhGGib4WvOFFZqIr6UAAtDYqQGrIN7lU+cFk5djFYYpp08QDOaodC18E4isVQKCAQAQaQ7Fg0SEeSrSY6/i01IRMsIMOBbZJaKB1yb+oErH0dwqE28hDWfjUjM4r23UKCtrMHNKLUTitfpJ6gteoZKPYt+zZV1EO8LkESXivJMeTnI+TL48ti7qHdRHaaB0o6CBAY2Qf+ZaEWxqzDCNI1QPQEqsZhu9qX5e3P24sYU/qvt4PY8Io7JZ1i86fpgSwUDGiIBFb3Vv4elzoJiGkEJdUKupDm0LTCCkjy4jf6LC5P2r6AyTNXuIPxOKzrVoiQXr1cxR1KS8wkruavordrAAz3TkX6eNJqWwTIEuGjJkuSySHtxMwGegtHApCvBqfj2Yn3oFoPYIrsq1+vbN8fPBAoIBABBpDsWDRIR5KtJjr+LTUhEywgw4FtklooHXJv6gSsfR3CoTbyENZ+NSMzivbdQoK2swc0otROK1+knqC16hko9i37NlXUQ7wuQRJeK8kx5Ocj5Mvjy2Luod1EdpoHSjoIEBjZB/5loRbGrMMI0jVA9ASqxmG72pfl7c/bixhT+q+3g9jwijslnWLzp+mBLBQMaIgEVvdW/h6XOgmIaQQl1Qq6kObQtMIKSPLiN/osLk/avoDJM1e4g/E4rOtWiJBevVzFHUpLzCSu5q+it2sADPdORfp40mpbBMgS4aMmS5LJIe3EzAZ6C0cCkK8Gp+PZifegWg9giuyrX69s3x88ECgYEAvgEhGvFghbvjzTa8z8cDXEnzZipxYcCaQG487LYKWat0eAnpqADRty/OFaRokgzw47J1oQmJeKGZniPkZRR1A0e2vOkkHupbz/zdhZGweSRNGr8sN59tITTySfqUxDOgNY32umrNqmJSpyG9mWeoMlg2v9M5/Jx6QoyPPcAiFdECgYEAu6CHU8EpitlozAnr6QYg4PkQ25UomrqdSNlXtoFi1wPdRp/mVdo6oryT6L6j7HcZ34/GTpj2u6AabB3fyYOxkVUqjopOJpHJTeTKwNm19MXnkAX3JAgpJ+Xsf2cmgETgDauZCQIVOq7VZ4xi/Cas29pHZ0XHlnNpmcFgXR9/20UCgYB5Mqc3VHjJVYx9vki6EKwoFlPX+4LPY9gA+VCLfaMkh6WHXGta6wra2veN/o1lfDO8Sn2V90tlU091/FcX0vDA4uHBpsWPotZl2VpEdSYoX+t/ACroYB1wbSGP5vM2I+gxwRh82NvPr2Ahk/go/mHfmz1xJv96DyY9hQNp1EDpwQKBgGn0KBebACuhxHVcsPUBefWxkNx/adOeyI1H9ylf/YHwc7ebOoaG2w/lMB2B8q3pQBooZdMivEqOCf2+DQ8OKGsqzgJ6hdFwCF7NcdXf28njLHX/eGXHmf4m8BuuE2bh/iiaG6yjmXtvGaIE/CzqZjktFZ9zH1eNyzeBpTpRPHGFAoGAUqvGAfAkMR0tir6YeRZX9LuvrMXCl4xEiefhm962lJSKojay92AxlNMzkLxbvOJhlQ6uChZsHYV5y1SNeQiaDUlgpK6k7JL972GBY0JikIsga9R/vfUQxF500+m/vjmIPyMMfximSQ2LDlIyQCa6RH37QhC5quin1HqkEi/BNoQ=-----END RSA PRIVATE KEY-----",
                            recipientPublicKey: "-----BEGIN RSA PUBLIC KEY-----MIIBCgKCAQEAi0H4VCFY/juThqE9X5rc2PI3/Fu41vIqel7DkHekx/fpUyeE1tCpvZMpKmripojA5gp9lZ1BRGmTVo9OnZ2XN/e/xMRjoPdivc4k7DnfA5lCnlinpKiksBr+0I/9SmteylXwF0CAJenflr4uHo7oDasjqB48QUaSl1TYLdnxyS/i8wDhMj+l1P5nwJp8t07aCyOCN/wy41h2iS57NmRN37dXf55F+dki0komhKc0DOaeB8kP3Oi12vcoQHLgtIoa7Dn4VldoTaw/8qA9Wgal2gMAfAhGGib4WvOFFZqIr6UAAtDYqQGrIN7lU+cFk5djFYYpp08QDOaodC18E4isVQIDAQAB-----END RSA PUBLIC KEY-----",
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shadowColor: Colors.black,
                        elevation: 3,
                        label: const Text(
                          "Recent message",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: ActionChip(
                          onPressed: () {
                            //! Navigate user to Active Users Page.
                            Navigator.of(context).pushNamed(RoutesNames.activeUserPage);
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          label: const Text(
                            "Active",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color.fromARGB(255, 0, 191, 108),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          //! User Chat List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firebaseFireStoreMethods.fetchingUsers(),
              builder: (context, snapshot) {
                // If snapshot is still loading then show CircularProgressIndicator.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // If snapshot has error then show error message.
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                // If snapshot has data then show ListView.builder.
                if (snapshot.hasData) {
                  // Here we are converting the snapshot data into List<UserModel>.
                  final List<UserModel> listofUser = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: listofUser.length,
                    itemBuilder: (context, index) {
                      // retiving each user data from UserModal.
                      final user = listofUser[index];

                      // This method get called for every other User and we pass with his userID.
                      context.read<LastMessageProvider>().fetchLastMsg(otherUserID: user.userID);

                      return ListTile(
                        onTap: () {
                          //! Navigate user to Chat Screen Page.
                          Navigator.of(context).pushNamed(
                            RoutesNames.chatScreenPage,
                            arguments: {
                              "userID": user.userID,
                              "name": user.name,
                              "email": user.email,
                              "imageUrl": user.imageUrl,
                              "isOnline": user.isOnline,
                              "lastSeen": user.lastSeen,
                              "rsaPublicKey": user.rsaPublicKey,
                            },
                          );
                        },
                        leading: Stack(
                          children: [
                            user.provider == "Email & Password"
                                ? CircleAvatar(
                                    backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 0, 191, 108) : const Color.fromARGB(255, 45, 67, 83),
                                    radius: 25,
                                    child: Text(
                                      user.name.substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: CachedNetworkImage(
                                      fit: BoxFit.fitHeight,
                                      width: 50,
                                      height: 50,
                                      imageUrl: user.imageUrl,
                                      errorWidget: (context, url, error) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ),
                            //! If User online then we show green dot.
                            user.isOnline
                                ? Positioned(
                                    bottom: 1.5,
                                    right: 1.5,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 0, 191, 108),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  )
                                // else we show SizedBox().
                                : const SizedBox(),
                          ],
                        ),
                        title: Text(
                          user.name,
                          maxLines: 1,
                        ),
                        //! if UnseenMessage List is Empty then we show the last Msg in subtitle as normal text other wise we show lastMsg in BOLD Text.
                        subtitle: user.unSeenMessages!.isEmpty
                            ? Selector<LastMessageProvider, String>(
                                // Here we fetch the Last Message of other User ID from Map that we create and we store the lastMsg with the key name of his User ID so it will very easy to retive
                                // because we can fetch easly with provided UserID from map.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              )
                            : Selector<LastMessageProvider, String>(
                                // Here we fetch the Last Message of other User ID from Map that we create and we store the lastMsg with the key name of his User ID so it will very easy to retive
                                // because we can fetch easly with provided UserID from map.
                                selector: (context, provider) => provider.getLastMsg(user.userID),
                                builder: (context, value, child) {
                                  return Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              ),
                        //! if UnseenMessage List is Empty then...
                        trailing: user.unSeenMessages!.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  DateTimeCalculatorForUsers.getLastActiveTime(lastSeen: user.lastSeen.toDate(), isOnline: user.isOnline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MediaQuery.of(context).platformBrightness == Brightness.light ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 216, 204, 204),
                                  ),
                                ),
                              )
                            //! If UnserSeenMessage Contains the Message then...
                            : user.unSeenMessages!.last.reciverId == _auth.currentUser!.uid
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 80),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateTimeCalculatorForUnseenmsg.getLastActiveTime(lastSeen: user.unSeenMessages!.last.timeStamp.toDate()),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(255, 0, 191, 108),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 0),
                                            child: Text(
                                              user.unSeenMessages!.length.toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      DateTimeCalculatorForUsers.getLastActiveTime(lastSeen: user.lastSeen.toDate(), isOnline: user.isOnline),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 116, 114, 114),
                                      ),
                                    ),
                                  ),
                      );
                    },
                  );
                }

                // else condiation
                else {
                  return const Center(
                    child: Text("Else Condition"),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 0, 191, 108),
        onPressed: () {},
        child: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
    );
  }
}
