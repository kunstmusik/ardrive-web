import 'dart:async';

import 'package:ardrive/components/keyboard_handler.dart';
import 'package:ardrive/dev_tools/app_dev_tools.dart';
import 'package:ardrive/dev_tools/shortcut_handler.dart';
import 'package:ardrive/turbo/topup/blocs/payment_form/payment_form_bloc.dart';
import 'package:ardrive/turbo/topup/blocs/turbo_topup_flow_bloc.dart';
import 'package:ardrive/turbo/utils/utils.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TurboPaymentFormView extends StatefulWidget {
  const TurboPaymentFormView({super.key});

  @override
  State<TurboPaymentFormView> createState() => TurboPaymentFormViewState();
}

class TurboPaymentFormViewState extends State<TurboPaymentFormView> {
  CardFieldInputDetails? card;

  @override
  Widget build(BuildContext context) {
    final theme = ArDriveTheme.of(context).themeData;

    final textTheme = theme.copyWith(
      textFieldTheme: theme.textFieldTheme.copyWith(
        inputTextStyle: theme.textFieldTheme.inputTextStyle.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.5,
          fontSize: 16,
        ),
        requiredLabelColor: theme.colors.themeAccentDisabled,
        labelColor: theme.colors.themeAccentDisabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
      ),
    );

    return ArDriveTheme(
      key: const ValueKey('turbo_payment_form'),
      themeData: textTheme,
      child: ScreenTypeLayout(
        mobile: _mobileView(context),
        desktop: _desktopView(context, textTheme.textFieldTheme),
      ),
    );
  }

  Widget _mobileView(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _header(context),
        const Divider(height: 16),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _desktopView(BuildContext context, ArDriveTextFieldTheme theme) {
    return ArDriveDevToolsShortcuts(
      customShortcuts: [
        Shortcut(
          modifier: LogicalKeyboardKey.shiftLeft,
          key: LogicalKeyboardKey.keyT,
          action: () {
            ArDriveDevTools.instance.showDevTools(optionalContext: context);
          },
        )
      ],
      child: Container(
        color: ArDriveTheme.of(context).themeData.colors.themeBgCanvas,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 26, right: 26),
                  child: ArDriveClickArea(
                    child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ArDriveIcons.x()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                ),
                child: Column(
                  children: [
                    _header(context),
                    const Divider(height: 24),
                    _credits(context),
                    const SizedBox(height: 16),
                    _formDesktop(
                      context,
                      theme,
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              const SizedBox(height: 24),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quoteRefresh(BuildContext context) {
    return const QuoteRefreshWidget();
  }

  Widget _credits(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<PaymentFormBloc, PaymentFormState>(
                  builder: (context, state) {
                    return Text(
                      '${convertCreditsToLiteralString(state.priceEstimate.credits)} Credits',
                      style: ArDriveTypography.body.leadBold(),
                    );
                  },
                ),
                BlocBuilder<PaymentFormBloc, PaymentFormState>(
                  builder: (context, state) {
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '\$${state.priceEstimate.priceInCurrency.toStringAsFixed(2)}',
                            style: ArDriveTypography.body.captionBold(
                              color: ArDriveTheme.of(context)
                                  .themeData
                                  .colors
                                  .themeFgMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _quoteRefresh(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // TODO: localize
            'Payment Details',
            style: ArDriveTypography.body
                .leadBold()
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            // TODO: localize
            'This is a one-time payment, powered by Stripe.',
            style: ArDriveTypography.body.captionBold(
              color:
                  ArDriveTheme.of(context).themeData.colors.themeAccentDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ArDriveClickArea(
            child: GestureDetector(
              onTap: () {
                context
                    .read<TurboTopupFlowBloc>()
                    .add(const TurboTopUpShowEstimationView());
              },
              child: Text(
                // TODO: localize
                'Back',
                style: ArDriveTypography.body.buttonLargeBold(
                  color: ArDriveTheme.of(context)
                      .themeData
                      .colors
                      .themeAccentDisabled,
                ),
              ),
            ),
          ),
          ArDriveButton(
            maxHeight: 44,
            maxWidth: 143,
            // TODO: localize
            text: 'Review',
            fontStyle: ArDriveTypography.body.buttonLargeBold(
              color: Colors.white,
            ),
            isDisabled: !(card?.complete ?? false),
            onPressed: () {
              // TODO: check payment-form-and-checkout branch
              context.read<TurboTopupFlowBloc>().add(
                    TurboTopUpShowPaymentReviewView(),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _formDesktop(BuildContext context, ArDriveTextFieldTheme theme) {
    final isDarkMode = ArDriveTheme.of(context).themeData.name == 'dark';

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextFieldLabel(
                text: 'Credit Card *',
                style: ArDriveTypography.body.buttonNormalBold(
                  color: theme.requiredLabelColor,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDarkMode
                  ? ArDriveTheme.of(context).themeData.colors.themeFgDefault
                  : null,
            ),
            child: CardField(
              style: ArDriveTheme.of(context)
                  .themeData
                  .textFieldTheme
                  .inputTextStyle
                  .copyWith(fontSize: 14),
              decoration: InputDecoration(
                enabledBorder: _getEnabledBorder(
                  ArDriveTheme.of(context).themeData.textFieldTheme,
                ),
                focusedBorder: _getFocusedBoder(
                  ArDriveTheme.of(context).themeData.textFieldTheme,
                ),
                errorBorder: _getErrorBorder(
                  ArDriveTheme.of(context).themeData.textFieldTheme,
                ),
                disabledBorder: _getDisabledBorder(
                  ArDriveTheme.of(context).themeData.textFieldTheme,
                ),
                focusColor: ArDriveTheme.of(context)
                    .themeData
                    .textFieldTheme
                    .inputPlaceholderColor,
                fillColor: ArDriveTheme.of(context)
                    .themeData
                    .textFieldTheme
                    .inputPlaceholderColor,
                contentPadding: const EdgeInsets.fromLTRB(13, 0, 13, 0),
              ),
              onCardChanged: (c) {
                setState(() {
                  card = c;
                });
              },
            ),
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  InputBorder _getBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  InputBorder _getEnabledBorder(
    ArDriveTextFieldTheme theme,
  ) {
    if (card?.complete ?? false) {
      return _getSuccessBorder(theme);
    }

    return _getBorder(theme.defaultBorderColor);
  }

  InputBorder _getFocusedBoder(ArDriveTextFieldTheme theme) {
    return _getBorder(
      ArDriveTheme.of(context).themeData.colors.themeFgDefault,
    );
  }

  InputBorder _getDisabledBorder(ArDriveTextFieldTheme theme) {
    return _getBorder(theme.inputDisabledBorderColor);
  }

  InputBorder _getErrorBorder(ArDriveTextFieldTheme theme) {
    return _getBorder(theme.errorBorderColor);
  }

  InputBorder _getSuccessBorder(ArDriveTextFieldTheme theme) {
    return _getBorder(theme.successBorderColor);
  }
}

class TimerWidget extends StatefulWidget {
  final int durationInSeconds;
  final VoidCallback onFinished;
  final TextStyle? textStyle;
  final Widget Function(BuildContext context, int secondsLeft)? builder;

  const TimerWidget({
    super.key,
    required this.durationInSeconds,
    required this.onFinished,
    this.textStyle,
    this.builder,
  });

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    _secondsLeft = widget.durationInSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          // Timer completed, fetch the quote again or perform any desired action
          _timer.cancel();
          widget.onFinished(); // Call the provided callback function
        }
      });
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder != null
        ? widget.builder!(context, _secondsLeft)
        : Text(
            _formatDuration(_secondsLeft),
            style: widget.textStyle,
          );
  }
}

abstract class InputDropdownItem {
  const InputDropdownItem(this.label);

  final String label;
}

class InputDropdownMenu<T extends InputDropdownItem> extends StatefulWidget {
  const InputDropdownMenu({
    super.key,
    required this.items,
    this.selectedItem,
    required this.buildSelectedItem,
    this.label,
    this.onChanged,
    this.anchor = const Aligned(
      follower: Alignment.topLeft,
      target: Alignment.bottomLeft,
      offset: Offset(0, 4),
    ),
    this.itemsTextStyle,
  });

  final List<T> items;
  final T? selectedItem;
  final Widget Function(T?) buildSelectedItem;
  final String? label;
  final Function(T)? onChanged;
  final Anchor anchor;
  final TextStyle? itemsTextStyle;

  @override
  State<InputDropdownMenu> createState() => _InputDropdownMenuState<T>();
}

class _InputDropdownMenuState<T extends InputDropdownItem>
    extends State<InputDropdownMenu<T>> {
  T? _selectedItem;

  @override
  initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return ArDriveClickArea(
      child: ArDriveDropdown(
        anchor: widget.anchor,
        width: 200,
        items: widget.items
            .map(
              (e) => ArDriveDropdownItem(
                content: Center(
                  child: Text(
                    e.label,
                    style: widget.itemsTextStyle ??
                        ArDriveTypography.body.captionBold(
                          color: ArDriveTheme.of(context)
                              .themeData
                              .textFieldTheme
                              .inputTextStyle
                              .color,
                        ),
                  ),
                ),
                onClick: () {
                  setState(() {
                    _selectedItem = e;
                  });

                  if (widget.onChanged != null) {
                    widget.onChanged!(e);
                  }
                },
              ),
            )
            .toList(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextFieldLabel(
                    text: widget.label!,
                    style: ArDriveTypography.body.buttonNormalBold(
                      color: ArDriveTheme.of(context)
                          .themeData
                          .textFieldTheme
                          .requiredLabelColor,
                    ),
                  ),
                ),
              ),
            widget.buildSelectedItem(_selectedItem),
          ],
        ),
      ),
    );
  }
}

class CountryItem implements InputDropdownItem {
  @override
  final String label;

  const CountryItem(this.label);
}

class CountryInputDropdown extends InputDropdownMenu<CountryItem> {
  const CountryInputDropdown({
    Key? key,
    required List<CountryItem> items,
    required Widget Function(CountryItem?) buildSelectedItem,
    CountryItem? selectedItem,
    required Function(CountryItem) onChanged,
  }) : super(
          key: key,
          items: items,
          selectedItem: selectedItem,
          buildSelectedItem: buildSelectedItem,
          label: 'Country *',
          onChanged: onChanged,
        );
}

class QuoteRefreshWidget extends StatefulWidget {
  const QuoteRefreshWidget({super.key});

  @override
  QuoteRefreshWidgetState createState() => QuoteRefreshWidgetState();
}

class QuoteRefreshWidgetState extends State<QuoteRefreshWidget> {
  @override
  Widget build(BuildContext context) {
    return ArDriveCard(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: localize
              Text(
                'Quote updates in ',
                style: ArDriveTypography.body.captionBold(
                  color:
                      ArDriveTheme.of(context).themeData.colors.themeFgDisabled,
                ),
              ),
              BlocBuilder<PaymentFormBloc, PaymentFormState>(
                builder: (context, state) {
                  return TimerWidget(
                    key: state is PaymentFormQuoteLoaded
                        ? const ValueKey('reset_timer')
                        : null,
                    durationInSeconds: state.quoteExpirationTimeInSeconds,
                    onFinished: () {
                      logger.d('fetching quote');
                      context
                          .read<PaymentFormBloc>()
                          .add(PaymentFormUpdateQuote());
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          BlocBuilder<PaymentFormBloc, PaymentFormState>(
            builder: (context, state) {
              if (state is PaymentFormLoadingQuote) {
                return const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                );
              }

              return ArDriveClickArea(
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<PaymentFormBloc>()
                        .add(PaymentFormUpdateQuote());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ArDriveIcons.refresh(
                        color: ArDriveTheme.of(context)
                            .themeData
                            .colors
                            .themeFgDisabled,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      // TODO: localize
                      Text(
                        'Refresh',
                        style: ArDriveTypography.body.captionBold(
                          color: ArDriveTheme.of(context)
                              .themeData
                              .colors
                              .themeFgDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
