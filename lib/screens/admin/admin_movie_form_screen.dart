import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/admin/admin_movie.dart';
import '../../providers/admin/movie_management_provider.dart';

class AdminMovieFormScreen extends StatefulWidget {
  final AdminMovie? movie;
  final int? tmdbId;
  final String? initialTitle;
  final String? initialPosterPath;
  final String? initialOverview;
  final String? initialReleaseDate;

  const AdminMovieFormScreen({
    super.key,
    this.movie,
    this.tmdbId,
    this.initialTitle,
    this.initialPosterPath,
    this.initialOverview,
    this.initialReleaseDate,
  });

  @override
  State<AdminMovieFormScreen> createState() => _AdminMovieFormScreenState();
}

class _AdminMovieFormScreenState extends State<AdminMovieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _overviewCtrl;
  late TextEditingController _posterCtrl;
  late TextEditingController _genresCtrl;
  late TextEditingController _runtimeCtrl;
  late TextEditingController _releaseDateCtrl;
  String _status = 'published';
  bool _featured = false;
  bool _isSaving = false;

  bool get _isEditing => widget.movie != null;

  @override
  void initState() {
    super.initState();
    final m = widget.movie;
    _titleCtrl = TextEditingController(
      text: m?.title ?? widget.initialTitle ?? '',
    );
    _overviewCtrl = TextEditingController(
      text: m?.overview ?? widget.initialOverview ?? '',
    );
    _posterCtrl = TextEditingController(
      text: m?.posterPath ?? widget.initialPosterPath ?? '',
    );
    _genresCtrl = TextEditingController(text: m?.genres ?? '');
    _runtimeCtrl = TextEditingController(
      text: m?.runtime != null && m!.runtime > 0 ? m.runtime.toString() : '',
    );
    _releaseDateCtrl = TextEditingController(
      text: m?.releaseDate ?? widget.initialReleaseDate ?? '',
    );
    if (m != null) {
      _status = m.status;
      _featured = m.featured;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _overviewCtrl.dispose();
    _posterCtrl.dispose();
    _genresCtrl.dispose();
    _runtimeCtrl.dispose();
    _releaseDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<MovieManagementProvider>();
      final updates = <String, dynamic>{
        'title': _titleCtrl.text,
        'overview': _overviewCtrl.text,
        'poster_path': _posterCtrl.text,
        'genres': _genresCtrl.text,
        if (_runtimeCtrl.text.isNotEmpty)
          'runtime': int.tryParse(_runtimeCtrl.text) ?? 0,
        'release_date': _releaseDateCtrl.text,
        'status': _status,
        'featured': _featured ? 1 : 0,
      };

      if (_isEditing) {
        await provider.updateMovie(widget.movie!.movieId, updates);
      } else if (widget.tmdbId != null) {
        updates['tmdb_id'] = widget.tmdbId;
        await provider.addMovie(tmdbId: widget.tmdbId!, title: _titleCtrl.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Movie updated' : 'Movie added'),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Movie' : 'Add Movie',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section(theme, 'Basic Info', [
              _buildField('Title', _titleCtrl, required: true),
              const SizedBox(height: 12),
              _buildField('Overview', _overviewCtrl, maxLines: 4),
            ]),
            const SizedBox(height: 20),
            _section(theme, 'Media', [
              _buildField('Poster Path', _posterCtrl,
                  hint: 'e.g. /abc123.jpg'),
              if (_posterCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w200${_posterCtrl.text}',
                      height: 120,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            _section(theme, 'Details', [
              Row(
                children: [
                  Expanded(
                    child: _buildField('Release Date', _releaseDateCtrl,
                        hint: 'YYYY-MM-DD'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Runtime (min)', _runtimeCtrl,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField('Genres', _genresCtrl,
                  hint: 'Comma-separated: Action, Drama'),
            ]),
            const SizedBox(height: 20),
            _section(theme, 'Settings', [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _decoration('Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Featured'),
                subtitle: Text(
                  'Show on homepage featured section',
                  style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.54)),
                ),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool required = false, int maxLines = 1, String? hint, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(label, hint: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
