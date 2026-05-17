import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_reveal.dart';
import '../widgets/app_page_route.dart';
import 'destination_card.dart';
import 'group_code_dialog.dart';
import 'my_groups_screen.dart';
import 'privacy_toggle.dart';
import 'search_bar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    this.embedded = false,
    this.onGroupCreated,
    super.key,
  });

  static const routeName = '/create-group';

  final bool embedded;
  final void Function(CreatedGroup group)? onGroupCreated;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  late final Future<List<Destination>> _destinationsFuture;
  final Set<int> _selectedDestinationIds = {};
  PrivacyMode _privacyMode = PrivacyMode.private;
  String _query = '';
  bool _isCreating = false;
  bool _headerScrolled = false;
  bool _headerVisible = true;
  late final ScrollController _scrollController;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _destinationsFuture = ApiService.instance.fetchDestinations(forceAll: true);
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;

    if (offset <= 0) {
      if (!_headerVisible || !_headerScrolled) {
        setState(() {
          _headerVisible = true;
          _headerScrolled = false;
        });
      }
      _lastScrollOffset = offset;
      return;
    }

    if (delta > 2 && _headerVisible) {
      setState(() {
        _headerVisible = false;
        _headerScrolled = true;
      });
    } else if (delta < -2 && !_headerVisible) {
      setState(() {
        _headerVisible = true;
        _headerScrolled = offset > 6;
      });
    } else if (_headerVisible && (offset > 6) != _headerScrolled) {
      setState(() => _headerScrolled = offset > 6);
    }

    _lastScrollOffset = offset;
  }

  void _toggleDestination(Destination destination) {
    setState(() {
      if (_selectedDestinationIds.contains(destination.id)) {
        _selectedDestinationIds.remove(destination.id);
      } else {
        _selectedDestinationIds.add(destination.id);
      }
    });

    final added = _selectedDestinationIds.contains(destination.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${destination.name} added to the group.'
              : '${destination.name} removed from the group.',
        ),
        duration: const Duration(milliseconds: 950),
      ),
    );
  }

  Future<void> _createGroup(List<Destination> destinations) async {
    final groupName = _groupNameController.text.trim();
    final selectedDestinations = destinations
        .where(
          (destination) => _selectedDestinationIds.contains(destination.id),
        )
        .toList(growable: false);

    if (groupName.isEmpty) {
      _showMessage('Name your travel group first.');
      return;
    }

    if (selectedDestinations.isEmpty) {
      _showMessage('Add at least one destination to the group.');
      return;
    }

    setState(() => _isCreating = true);
    final group = await ApiService.instance.createTravelGroup(
      groupName: groupName,
      privacyMode: _privacyMode,
      destinations: selectedDestinations,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isCreating = false);
    final nextStep = await showGroupCodeDialog(
      context: context,
      group: group,
    );

    if (!mounted) {
      return;
    }

    // Reset state fields upon successful creation so the screen is clean for the next group
    _groupNameController.clear();
    _searchController.clear();
    setState(() {
      _selectedDestinationIds.clear();
      _privacyMode = PrivacyMode.private;
      _query = '';
    });

    if (nextStep == 'my-groups') {
      if (widget.embedded) {
        widget.onGroupCreated?.call(group);
      } else {
        await replaceWithAppPage(context, const MyGroupsScreen());
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _cancel() {
    if (widget.embedded) {
      _groupNameController.clear();
      _searchController.clear();
      setState(() {
        _selectedDestinationIds.clear();
        _privacyMode = PrivacyMode.private;
        _query = '';
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _buildActionButtons(List<Destination> destinations) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isCreating ? null : _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCreating ? null : () => _createGroup(destinations),
            icon: _isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.group_add_rounded),
            label: const Text('Create Group'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<List<Destination>> snapshot) {
    final destinations = snapshot.data ?? const <Destination>[];
    final selectedDestinations = destinations
        .where(
          (destination) => _selectedDestinationIds.contains(destination.id),
        )
        .toList(growable: false);
    final filteredDestinations = _filteredDestinations(destinations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topLeft,
            heightFactor: _headerVisible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _StickyCreateHeader(
              compact: widget.embedded,
              showBack: !widget.embedded,
              showShadow: _headerScrolled && _headerVisible,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              widget.embedded ? 20 : 24,
            ),
            children: [
                AnimatedReveal(
                  delay: const Duration(milliseconds: 90),
                  child: _GroupSetupSection(
                    groupNameController: _groupNameController,
                    privacyMode: _privacyMode,
                    onPrivacyChanged: (mode) {
                      setState(() => _privacyMode = mode);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedReveal(
                  delay: const Duration(milliseconds: 150),
                  child: _DestinationSelectionSection(
                    searchController: _searchController,
                    selectedDestinations: selectedDestinations,
                    destinations: filteredDestinations,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                    onSearchChanged: (value) {
                      setState(() => _query = value);
                    },
                    onRemoveSelected: _toggleDestination,
                    onToggleDestination: _toggleDestination,
                    isSelected: (destination) =>
                        _selectedDestinationIds.contains(destination.id),
                  ),
                ),
                if (widget.embedded) ...[
                  const SizedBox(height: 20),
                  if (snapshot.hasData) _buildActionButtons(destinations),
                  const SizedBox(height: 8),
                ],
              ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<Destination>>(
      future: _destinationsFuture,
      builder: (context, snapshot) => _buildBody(context, snapshot),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.explorerGradient(),
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: FutureBuilder<List<Destination>>(
          future: _destinationsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            return _buildActionButtons(snapshot.data!);
          },
        ),
      ),
    );
  }

  List<Destination> _filteredDestinations(List<Destination> destinations) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return destinations;
    }

    return destinations
        .where((destination) {
          return destination.name.toLowerCase().contains(normalizedQuery) ||
              destination.country.toLowerCase().contains(normalizedQuery) ||
              destination.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }
}

class _StickyCreateHeader extends StatelessWidget {
  const _StickyCreateHeader({
    required this.compact,
    required this.showBack,
    required this.showShadow,
    required this.onBack,
  });

  final bool compact;
  final bool showBack;
  final bool showShadow;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.paleMint,
            Colors.white.withValues(alpha: 0.97),
            AppTheme.mint.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepTeal.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          if (showShadow)
            BoxShadow(
              color: AppTheme.deepTeal.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
        ],
        border: Border.all(
          color: AppTheme.line.withValues(alpha: 0.6),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, compact ? 0 : 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBack) ...[
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: onBack,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Create a Travel Group',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Set up your group and start choosing destinations.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.deepTeal,
        fixedSize: const Size(46, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _GroupSetupSection extends StatelessWidget {
  const _GroupSetupSection({
    required this.groupNameController,
    required this.privacyMode,
    required this.onPrivacyChanged,
  });

  final TextEditingController groupNameController;
  final PrivacyMode privacyMode;
  final ValueChanged<PrivacyMode> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group Setup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: groupNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              prefixIcon: Icon(Icons.edit_location_alt_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Text('Privacy Mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          PrivacyToggle(value: privacyMode, onChanged: onPrivacyChanged),
        ],
      ),
    );
  }
}

class _DestinationSelectionSection extends StatelessWidget {
  const _DestinationSelectionSection({
    required this.searchController,
    required this.selectedDestinations,
    required this.destinations,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onRemoveSelected,
    required this.onToggleDestination,
    required this.isSelected,
  });

  final TextEditingController searchController;
  final List<Destination> selectedDestinations;
  final List<Destination> destinations;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Destination> onRemoveSelected;
  final ValueChanged<Destination> onToggleDestination;
  final bool Function(Destination destination) isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Destinations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _SelectedDestinationStrip(
            destinations: selectedDestinations,
            onRemove: onRemoveSelected,
          ),
          const SizedBox(height: 16),
          DestinationSearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (destinations.isEmpty)
            const _EmptyDestinations()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 580;
                return GridView.builder(
                  itemCount: destinations.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isCompact ? 420 : 280,
                    mainAxisExtent: 342,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return AnimatedReveal(
                      delay: Duration(milliseconds: index * 45),
                      child: CreateGroupDestinationCard(
                        destination: destination,
                        selected: isSelected(destination),
                        onPressed: () => onToggleDestination(destination),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SelectedDestinationStrip extends StatelessWidget {
  const _SelectedDestinationStrip({
    required this.destinations,
    required this.onRemove,
  });

  final List<Destination> destinations;
  final ValueChanged<Destination> onRemove;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.paleMint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_location_alt_rounded,
              color: AppTheme.teal,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected destinations will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return InputChip(
            label: Text(destination.name),
            avatar: const Icon(Icons.place_rounded, size: 18),
            onDeleted: () => onRemove(destination),
            deleteIcon: const Icon(Icons.close_rounded, size: 18),
            backgroundColor: AppTheme.mint,
            side: const BorderSide(color: AppTheme.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDestinations extends StatelessWidget {
  const _EmptyDestinations();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.paleMint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_off_rounded, color: AppTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No destinations match your search.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
