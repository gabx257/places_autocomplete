library google_maps_places_autocomplete_widgets;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/place_api_provider.dart';
import '/model/suggestion.dart';
import '/model/place.dart';

abstract class AddresssAutocompleteStatefulWidget extends StatefulWidget {
  const AddresssAutocompleteStatefulWidget({super.key});

  /// Callback triggered before sending query to google places API.
  /// This allows the caller to prepare the query, modifying it in any way.  It might be
  /// used for adding things like City, State, Zip that may be already entered in other
  /// form elements.
  abstract final String Function(String address)? prepareQuery;

  ///Callback triggered when user clicks clear icon.  This can be useful if the caller wants to clear other
  /// address fields that may be in their form.
  abstract final void Function()? onClearClick;

  ///Callback triggered when a address item is selected, allows chance to
  /// clear other fields awaiting [Place] details in [onSuggestionClick]
  /// or to use the [Suggestion] information directly.
  abstract final void Function(Suggestion suggestion)? onInitialSuggestionClick;

  ///Callback triggered when after Place has been retreived after item is selected
  abstract final void Function(Place place)? onSuggestionClick;

  //callback triggered when losing focus but no suggestion was selected
  abstract final void Function(String text)? onFinishedWithNoSuggestion;

  ///Callback triggered when a
  /// item is selected
  abstract final String? Function(Place place)?
      onSuggestionClickGetTextToUseForControl;

  ///your maps api key, must not be null if you are not using a proxy server
  abstract final String? mapsApiKey;

  ///proxy server for autocomplete requests, must not be null if you are not using a mapsApiKey
  ///if you are using a proxy server, you must also provide a [proxyServerDetails]
  abstract final Uri? proxyServerAutocomplete;

  ///proxy server for place details requests, must not be null if you are using a proxy server
  ///if you are using a proxy server, you must also provide a [proxyServerAutocomplete]
  abstract final Uri? proxyServerDetails;

  ///builder used to render each item displayed
  ///must not be null
  abstract final Widget Function(Suggestion, int)? buildItem;

  ///Hover color around [buildItem] widget on desktop platforms.
  abstract final Color? hoverColor;

  ///Selection color around [buildItem] widget on desktop platforms.
  abstract final Color? selectionColor;

  ///builder used to render a clear, it can be null, but in that case, a clear button is not displayed
  abstract final Icon? clearButton;

  ///BoxDecoration for the suggestions external container
  abstract final BoxDecoration? suggestionsOverlayDecoration;

  ///Elevation for the suggestion list
  abstract final double? elevation;

  ///Offset between the TextField and the Overlay
  abstract final double overlayOffset;

  ///if true, shows "powered by google" inside the suggestion list, after its items
  abstract final bool showGoogleTradeMark;

  ///used to narrow down address search
  abstract final List<String>? componentCountry;

  ///Inform Google places of desired language the results should be returned.
  abstract final String? language;

  ///PostalCode lookup instead of address lookup (defaults to false)
  abstract final bool postalCodeLookup;

  ///debounce time in milliseconds (default 600)
  abstract final int debounceTime;

  abstract final TextEditingController? controller;

  // These correspond to arguments supported by standard Flutter
  // TextField and TextFormField
  abstract final String? initialValue;
  abstract final FocusNode? focusNode;
  abstract final InputDecoration? decoration;
  abstract final TextInputType? keyboardType;
  abstract final TextCapitalization textCapitalization;
  abstract final TextInputAction? textInputAction;
  abstract final TextStyle? style;
  abstract final StrutStyle? strutStyle;
  abstract final TextDirection? textDirection;
  abstract final TextAlign textAlign;
  abstract final TextAlignVertical? textAlignVertical;
  abstract final bool autofocus;
  abstract final bool readOnly;
  abstract final bool? showCursor;

  abstract final MaxLengthEnforcement? maxLengthEnforcement;
  abstract final int? maxLines;
  abstract final int? minLines;
  abstract final bool expands;
  abstract final int? maxLength;
  abstract final ValueChanged<String>? onChanged;
  abstract final ValueChanged<Place?>? onSave;
}

mixin SuggestionOverlayMixin<T extends AddresssAutocompleteStatefulWidget>
    on State<T> {
  abstract final LayerLink layerLink;
  abstract final String sessionToken;
  abstract TextEditingController? controller;
  abstract FocusNode focusNode;
  abstract PlaceApiProvider placeApi;
  abstract OverlayEntry? entry;
  abstract Suggestion? selected;
  abstract List<Suggestion> suggestions;
  abstract Timer? debounceTimer;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    focusNode = widget.focusNode ?? FocusNode();

    assert((widget.proxyServerAutocomplete != null &&
            widget.proxyServerDetails != null) ||
        widget.mapsApiKey != null);

    placeApi = PlaceApiProvider(
        sessionToken: sessionToken,
        mapsApiKey: widget.mapsApiKey,
        componentCountry: widget.componentCountry,
        language: widget.language,
        proxyServerAutocomplete: widget.proxyServerAutocomplete,
        proxyServerDetails: widget.proxyServerDetails);

    focusNode.addListener(showOrHideOverlayOnFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller!.dispose(); // only dispose if we created it
      controller = null;
    }
    if (widget.focusNode == null) {
      focusNode.dispose(); // only dispose if we created it
    } else {
      // remove the listener so it's doesn't get stale, we will put it back later
      focusNode.removeListener(showOrHideOverlayOnFocusChange);
    }

    debounceTimer?.cancel();
    super.dispose();
  }

  void showOrHideOverlayOnFocusChange() {
    if (focusNode.hasFocus) {
      showOverlay();
    } else {
      hideOverlay();
    }
  }

  void showOverlay() {
    if (!context.mounted) return;
    if (context.findRenderObject() == null) return;
    final overlay = Overlay.of(context);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    entry = OverlayEntry(
        builder: (overlayContext) => Positioned(
              width: renderBox.size.width,
              child: CompositedTransformFollower(
                  link: layerLink,
                  showWhenUnlinked: false,
                  offset:
                      Offset(0, renderBox.size.height + widget.overlayOffset),
                  child: buildOverlay()),
            ));
    overlay.insert(entry!);
  }

  void hideOverlay({bool suggestionHasBeenSelected = false}) {
    if (entry != null) {
      entry?.remove();
      entry = null;
      if (!suggestionHasBeenSelected) {
        if (widget.onFinishedWithNoSuggestion != null) {
          widget.onFinishedWithNoSuggestion!(controller?.text ?? '');
        }
      }
    }
  }

  void _clearText() {
    setState(() {
      if (widget.onClearClick != null) {
        widget.onClearClick!();
      }
      controller?.clear();
      if (!focusNode.hasFocus) {
        if (widget.onFinishedWithNoSuggestion != null) {
          widget.onFinishedWithNoSuggestion!(controller?.text ?? '');
        }
      } else {
        focusNode.unfocus();
      }
      suggestions = [];
    });
  }

  /* ALTERNATE using ListView builder.. */
  Widget get buildListViewerBuilder {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int index) => InkWell(
        hoverColor: widget.hoverColor,
        highlightColor: widget.selectionColor,
        onTap: () async {
          if (index >= suggestions.length) return;

          selected = suggestions[index];
          hideOverlay(suggestionHasBeenSelected: true);
          focusNode.unfocus();

          if (widget.onInitialSuggestionClick != null) {
            widget.onInitialSuggestionClick!(selected!);
          }
          if (widget.onSuggestionClickGetTextToUseForControl != null ||
              widget.onSuggestionClick == null) return;
          // If they need more details now do async request
          // for Place details..
          Place place = await placeApi.getPlaceDetailFromId(selected!.placeId);

          if (widget.onSuggestionClickGetTextToUseForControl != null) {
            controller?.text =
                widget.onSuggestionClickGetTextToUseForControl!(place) ?? '';
          } else {
            // default to full formatted address
            controller?.text = place.formattedAddress ?? '';
          }
          if (widget.onSuggestionClick != null) {
            widget.onSuggestionClick!(place);
          }
        },
        child: widget.buildItem != null
            ? widget.buildItem!(suggestions[index], index)
            : defaultItemBuilder(suggestions[index], index),
      ),
    );
  }

  Widget buildOverlay() => TextFieldTapRegion(
        child: Material(
          color: widget.suggestionsOverlayDecoration != null
              ? widget.suggestionsOverlayDecoration!.color
              : Colors.white,
          elevation: widget.elevation ?? 0,
          child: Container(
            decoration:
                widget.suggestionsOverlayDecoration ?? const BoxDecoration(),
            child: Column(
              children: [
                buildListViewerBuilder, //...buildList(),
                if (widget.showGoogleTradeMark)
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text('powered by google'),
                  )
              ],
            ),
          ),
        ),
      );

  String _lastText = '';
  Future<void> searchAddress(String text) async {
    if (widget.prepareQuery != null) {
      text = widget.prepareQuery!(text);
    }
    if (text != _lastText && text.isNotEmpty) {
      _lastText = text;
      suggestions = await placeApi.fetchSuggestions(text);
    }
    if (entry != null) {
      entry!.markNeedsBuild();
    }
  }

  InputDecoration getInputDecoration() {
    if (widget.decoration != null) {
      if (widget.clearButton != null) {
        return widget.decoration!.copyWith(
            suffixIcon: IconButton(
          icon: widget.clearButton!,
          onPressed: _clearText,
        ));
      }
      return widget.decoration!;
    }
    return const InputDecoration();
  }

  void onTextChanges(text) async {
    if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
    debounceTimer =
        Timer(Duration(milliseconds: widget.debounceTime), () async {
      await searchAddress(text);
      if (widget.onChanged != null) {
        widget.onChanged!(text);
      }
    });
  }

  /// Provides default implementation of Suggestion list item builder
  Widget defaultItemBuilder(Suggestion suggestion, int index) {
    return Container(
        margin: const EdgeInsets.fromLTRB(2, 2, 2, 2),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.centerLeft,
        color: Colors.white,
        child: Text(suggestion.description));
  }
}
