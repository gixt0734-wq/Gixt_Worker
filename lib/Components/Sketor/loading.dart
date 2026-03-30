import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


Widget _buildLoadingShimmer() {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 105,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: 
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 25,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 370,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 25,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
          ),
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => 
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              width: 90,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
            )
           ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 25,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 0),
          ListView.builder(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20.0),
                              topLeft: Radius.circular(20.0),
                            ),
                            child: Container(
                              width: 130,
                              height: 130,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 30, width: 100, color: Colors.white),
                                const SizedBox(height: 10),
                                Row(children: [
                                  const Icon(Icons.groups_sharp, color: Colors.grey, size: 25),
                                  const SizedBox(width: 10),
                                  Container(height: 15, width: 100, color: Colors.white),
                                ]),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.room_service, color: Colors.grey, size: 25),
                                  const SizedBox(width: 10),
                                  Container(height: 15, width: 100, color: Colors.white),
                                ]),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.star_rounded, color: Colors.grey, size: 23),
                                  const SizedBox(width: 10),
                                  Container(height: 15, width: 100, color: Colors.white),
                                ]),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}