import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Searches the client registry (online) for [term].
typedef ClientRegistrySearch = Future<Result<List<ClientModel>>> Function(
    String term);

/// Searches the accounts already on the phone for [term] (offline fallback).
typedef KnownAccountSearch = List<ClientModel> Function(String term);

/// Pick one existing client: a sheet with a search box over the registry
/// (a_tblcollectionclient), results as the collector types.
///
/// Replaces typing an account name freehand, which saved a name that matched
/// no client (and so no client id) whenever it was spelled differently from
/// the registry. Offline it says so and searches the accounts already on the
/// phone instead, so the form still works in the field.
class ClientPickerSheet extends StatefulWidget {
  const ClientPickerSheet({
    super.key,
    required this.search,
    required this.searchKnown,
    this.selected,
  });

  final ClientRegistrySearch search;
  final KnownAccountSearch searchKnown;
  final ClientModel? selected;

  /// Open the picker; resolves to the chosen client, or null if dismissed.
  static Future<ClientModel?> show(
    BuildContext context, {
    required ClientRegistrySearch search,
    required KnownAccountSearch searchKnown,
    ClientModel? selected,
  }) =>
      showModalBottomSheet<ClientModel>(
        context: context,
        // Sized by its content up to most of the screen, and lifted by the
        // keyboard: the search box is focused the moment it opens.
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => ClientPickerSheet(
          search: search,
          searchKnown: searchKnown,
          selected: selected,
        ),
      );

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  /// Long enough that a typed word is one request, short enough to feel live.
  static const Duration _debounce = Duration(milliseconds: 300);

  final _query = TextEditingController();
  Timer? _timer;

  /// Only the newest request may write the list: a slow reply to "anti"
  /// must not replace the results for "antipolo".
  int _request = 0;

  List<ClientModel> _results = const [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    setState(() {}); // the clear button follows the text
    _timer = Timer(_debounce, () => _run(value));
  }

  Future<void> _run(String term) async {
    final id = ++_request;
    setState(() => _loading = true);
    final result = await widget.search(term);
    if (!mounted || id != _request) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _offline = false;
        _results = result.value;
      } else {
        _offline = true;
        _results = widget.searchKnown(term);
      }
    });
  }

  void _clear() {
    _query.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final term = _query.text.trim();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    // Outermost: the navigation bar, once. Inside: the keyboard, once.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: BDevicesUtils.keyboardInset(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace,
                    BSizes.sm, BSizes.defaultSpace, BSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: BSizes.md),
                        decoration: BoxDecoration(
                          color: BCollectionColors.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Choose an account',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: BSizes.spaceBtwItemsLight),
                    TextField(
                      key: const ValueKey('client-picker-search'),
                      controller: _query,
                      autofocus: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (v) {
                        _timer?.cancel();
                        _run(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or client code',
                        prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon:
                                    const Icon(Iconsax.close_circle5, size: 18),
                                onPressed: _clear,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // A hairline of progress, not a spinner in place of the list:
              // the previous results stay put while the next ones load.
              SizedBox(
                height: 2,
                child: _loading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : null,
              ),
              if (_offline)
                Container(
                  key: const ValueKey('client-picker-offline'),
                  margin: const EdgeInsets.fromLTRB(
                      BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: BSizes.spaceBtwItemsLight,
                      vertical: BSizes.sm),
                  decoration: BoxDecoration(
                    color: BCollectionColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.wifi_square,
                          size: 18, color: BCollectionColors.warning),
                      const SizedBox(width: BSizes.sm),
                      Expanded(
                        child: Text(
                          "Can't reach the client list. Showing the accounts "
                          'on this phone.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: _results.isEmpty && !_loading
                    ? _Empty(term: term, offline: _offline)
                    : ListView.separated(
                        shrinkWrap: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(BSizes.sm, BSizes.xs,
                            BSizes.sm, BSizes.defaultSpace),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: BSizes.md,
                            endIndent: BSizes.md,
                            color: BCollectionColors.outline),
                        itemBuilder: (context, i) => _ClientRow(
                          client: _results[i],
                          selected: _results[i].id == widget.selected?.id,
                          onTap: () => Navigator.of(context).pop(_results[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One client: the name to read, the code and address to tell two similar
/// names apart.
class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.client,
    required this.selected,
    required this.onTap,
  });

  final ClientModel client;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = client.address.trim();
    final detail = [
      client.code,
      if (address.isNotEmpty && address.toUpperCase() != 'N/A') address,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.sm, vertical: BSizes.spaceBtwItemsLight),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: BSizes.xxs),
                  Text(detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: BCollectionColors.inkMuted)),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: BSizes.sm),
              const Icon(Iconsax.tick_circle5,
                  size: 20, color: BCollectionColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.term, required this.offline});

  final String term;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = term.isEmpty
        ? (offline
            ? 'No accounts on this phone yet. Download the bucket, or try '
                'again with a connection.'
            : 'No clients found.')
        : 'No client matches "$term".';
    return Padding(
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      child: Text(message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: BCollectionColors.inkMuted)),
    );
  }
}
