import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../screens/movie_details_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final int watchCount;

  const MovieCard({super.key, required this.movie, this.watchCount = 0});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'movie_poster_${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(movie: movie),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (movie.posterUrl != null)
                  CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                    errorWidget: (_, _, _) => Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  )
                else
                  Container(color: Theme.of(context).cardColor, child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                if (movie.genres.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Text(
                        movie.genres.first,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (watchCount > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay, size: 14, color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '$watchCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
