import 'package:ardrive/misc/resources.dart';
import 'package:ardrive/pages/drive_detail/components/hover_widget.dart';
import 'package:ardrive/turbo/topup/blocs/payment_review/payment_review_bloc.dart';
import 'package:ardrive/turbo/topup/blocs/turbo_topup_flow_bloc.dart';
import 'package:ardrive/turbo/topup/views/topup_payment_form.dart';
import 'package:ardrive/turbo/topup/views/turbo_error_view.dart';
import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TurboReviewView extends StatefulWidget {
  const TurboReviewView({super.key});

  @override
  State<TurboReviewView> createState() => _TurboReviewViewState();
}

class _TurboReviewViewState extends State<TurboReviewView> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ArDriveTheme.of(context).themeData;

    // custom theme for the text fields on the top-up form
    final textTheme = theme.copyWith(
      textFieldTheme: theme.textFieldTheme.copyWith(
        inputBackgroundColor: theme.colors.themeBgCanvas,
        labelColor: theme.colors.themeAccentDisabled,
        requiredLabelColor: theme.colors.themeAccentDisabled,
        inputTextStyle: theme.textFieldTheme.inputTextStyle.copyWith(
          color: theme.colors.themeFgMuted,
          fontWeight: FontWeight.w600,
          height: 1.5,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 8,
        ),
        labelStyle: TextStyle(
          color: theme.colors.themeAccentDisabled,
          fontWeight: FontWeight.w600,
          height: 1.5,
          fontSize: 16,
        ),
      ),
    );

    return BlocListener<PaymentReviewBloc, PaymentReviewState>(
      listener: (context, state) {
        if (state is PaymentReviewPaymentSuccess) {
          context
              .read<TurboTopupFlowBloc>()
              .add(const TurboTopUpShowSuccessView());
        } else if (state is PaymentReviewPaymentError) {
          showAnimatedDialog(
            context,
            content: ArDriveStandardModal(
              width: 575,
              content: TurboErrorView(
                errorType: state.errorType,
                onDismiss: () {
                  // Navigator.pop(context);
                },
                onTryAgain: () {
                  Navigator.pop(context);
                  context.read<PaymentReviewBloc>().add(
                        PaymentReviewFinishPayment(),
                      );
                },
              ),
            ),
            barrierDismissible: false,
            barrierColor: ArDriveTheme.of(context)
                .themeData
                .colors
                .shadow
                .withOpacity(0.9),
          );
        } else if (state is PaymentReviewErrorLoadingPaymentModel) {
          showAnimatedDialog(
            context,
            content: ArDriveStandardModal(
              width: 575,
              content: TurboErrorView(
                errorType: TurboErrorType.fetchPaymentIntentFailed,
                onDismiss: () {},
                onTryAgain: () {
                  Navigator.pop(context);
                  context.read<PaymentReviewBloc>().add(
                        PaymentReviewLoadPaymentModel(),
                      );
                },
              ),
            ),
            barrierDismissible: false,
            barrierColor: ArDriveTheme.of(context)
                .themeData
                .colors
                .shadow
                .withOpacity(0.9),
          );
        }
      },
      child: BlocBuilder<PaymentReviewBloc, PaymentReviewState>(
        buildWhen: (previous, current) {
          return current is PaymentReviewPaymentModelLoaded ||
              current is PaymentReviewLoadingPaymentModel;
        },
        builder: (context, state) {
          if (state is PaymentReviewLoadingPaymentModel) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40.0),
                    child: Text(
                      'Review',
                      style: ArDriveTypography.body
                          .leadBold()
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: ArDriveCard(
                    contentPadding: const EdgeInsets.all(0),
                    backgroundColor:
                        ArDriveTheme.of(context).themeData.colors.shadow,
                    content: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 24, left: 24, right: 24),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SvgPicture.asset(
                                  Resources.images.brand.turbo,
                                  height: 15,
                                  color: ArDriveTheme.of(context)
                                      .themeData
                                      .colors
                                      .themeAccentDisabled,
                                  colorBlendMode: BlendMode.srcIn,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              BlocBuilder<PaymentReviewBloc,
                                  PaymentReviewState>(
                                builder: (context, state) {
                                  if (state
                                      is PaymentReviewPaymentModelLoaded) {
                                    return Text(
                                      state.credits,
                                      style: ArDriveTypography.headline
                                          .headline4Regular(
                                            color: ArDriveTheme.of(context)
                                                .themeData
                                                .colors
                                                .themeFgMuted,
                                          )
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    );
                                  }

                                  return Text(
                                    '0',
                                    style: ArDriveTypography.headline
                                        .headline4Regular(
                                      color: ArDriveTheme.of(context)
                                          .themeData
                                          .colors
                                          .themeFgMuted,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                'Credits',
                                style:
                                    ArDriveTypography.body.buttonLargeRegular(
                                  color: ArDriveTheme.of(context)
                                      .themeData
                                      .colors
                                      .themeAccentDisabled,
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Text(
                                    'Subtotal',
                                    style:
                                        ArDriveTypography.body.buttonNormalBold(
                                      color: ArDriveTheme.of(context)
                                          .themeData
                                          .colors
                                          .themeAccentDisabled,
                                    ),
                                  ),
                                  const Spacer(),
                                  BlocBuilder<PaymentReviewBloc,
                                      PaymentReviewState>(
                                    builder: (context, state) {
                                      if (state
                                          is PaymentReviewPaymentModelLoaded) {
                                        return Text(
                                          '\$${state.subTotal}',
                                          style: ArDriveTypography.body
                                              .buttonNormalBold(
                                            color: ArDriveTheme.of(context)
                                                .themeData
                                                .colors
                                                .themeAccentDisabled,
                                          ),
                                        );
                                      }

                                      return Text(
                                        '\$0',
                                        style: ArDriveTypography.body
                                            .buttonNormalBold(
                                          color: ArDriveTheme.of(context)
                                              .themeData
                                              .colors
                                              .themeAccentDisabled,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 32,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Fees',
                                    style:
                                        ArDriveTypography.body.buttonNormalBold(
                                      color: ArDriveTheme.of(context)
                                          .themeData
                                          .colors
                                          .themeAccentDisabled,
                                    ),
                                  ),
                                  const Spacer(),
                                  BlocBuilder<PaymentReviewBloc,
                                      PaymentReviewState>(
                                    builder: (context, state) {
                                      if (state
                                          is PaymentReviewPaymentModelLoaded) {
                                        return Text(
                                          // TODO: calculate the fee
                                          '\$${0.3}',
                                          style: ArDriveTypography.body
                                              .buttonNormalBold(
                                            color: ArDriveTheme.of(context)
                                                .themeData
                                                .colors
                                                .themeAccentDisabled,
                                          ),
                                        );
                                      }

                                      return Text(
                                        '\$0',
                                        style: ArDriveTypography.body
                                            .buttonNormalBold(
                                          color: ArDriveTheme.of(context)
                                              .themeData
                                              .colors
                                              .themeAccentDisabled,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 32,
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Total',
                                    style: ArDriveTypography.body
                                        .buttonNormalBold(),
                                  ),
                                  const Spacer(),
                                  BlocBuilder<PaymentReviewBloc,
                                      PaymentReviewState>(
                                    builder: (context, state) {
                                      if (state
                                          is PaymentReviewPaymentModelLoaded) {
                                        return Text(
                                          '\$${state.total}',
                                          style: ArDriveTypography.body
                                              .buttonNormalBold()
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        );
                                      }

                                      return Text(
                                        // '\$${state.total}',
                                        '\$0',
                                        style: ArDriveTypography.body
                                            .buttonNormalBold()
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        BlocBuilder<PaymentReviewBloc, PaymentReviewState>(
                          builder: (context, state) {
                            if (state is PaymentReviewPaymentModelLoaded) {
                              return Container(
                                color: ArDriveTheme.of(context)
                                    .themeData
                                    .colors
                                    .themeBgSurface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                child: Row(
                                  children: [
                                    TimerWidget(
                                      key: state is PaymentReviewQuoteLoaded
                                          ? const ValueKey('quote_loaded')
                                          : null,
                                      durationInSeconds: state
                                          .quoteExpirationDate
                                          .difference(DateTime.now())
                                          .inSeconds,
                                      onFinished: () {
                                        context
                                            .read<PaymentReviewBloc>()
                                            .add(PaymentReviewRefreshQuote());
                                      },
                                      builder: (context, seconds) {
                                        Color textColor;
                                        if (seconds < 30) {
                                          textColor = ArDriveTheme.of(context)
                                              .themeData
                                              .colors
                                              .themeErrorDefault;
                                        } else if (seconds < 60) {
                                          textColor = ArDriveTheme.of(context)
                                              .themeData
                                              .colors
                                              .themeWarningMuted;
                                        } else {
                                          textColor = ArDriveTheme.of(context)
                                              .themeData
                                              .colors
                                              .themeAccentDisabled;
                                        }

                                        String formatDuration(int seconds) {
                                          int minutes = seconds ~/ 60;
                                          int remainingSeconds = seconds % 60;
                                          String minutesStr = minutes
                                              .toString()
                                              .padLeft(2, '0');
                                          String secondsStr = remainingSeconds
                                              .toString()
                                              .padLeft(2, '0');
                                          return '$minutesStr:$secondsStr';
                                        }

                                        if (state
                                            is PaymentReviewLoadingQuote) {
                                          return Text(
                                            'Fetching new quote...',
                                            style: ArDriveTypography.body
                                                .buttonNormalBold()
                                                .copyWith(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          );
                                        } else if (state
                                            is PaymentReviewQuoteError) {
                                          return Text(
                                            'Error fetching new quote, try again.',
                                            style: ArDriveTypography.body
                                                .buttonNormalBold(
                                                  color:
                                                      ArDriveTheme.of(context)
                                                          .themeData
                                                          .colors
                                                          .themeErrorDefault,
                                                )
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          );
                                        }

                                        return RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Quote updates in ',
                                                style: ArDriveTypography.body
                                                    .buttonNormalBold()
                                                    .copyWith(
                                                      color: ArDriveTheme.of(
                                                              context)
                                                          .themeData
                                                          .colors
                                                          .themeAccentDisabled,
                                                    ),
                                              ),
                                              TextSpan(
                                                text: formatDuration(seconds),
                                                style: ArDriveTypography.body
                                                    .buttonNormalBold()
                                                    .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    RefreshQuoteButton(),
                                  ],
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 40.0, right: 40, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please leave an email if you want a receipt.',
                        style: ArDriveTypography.body.buttonNormalBold(
                          color: ArDriveTheme.of(context)
                              .themeData
                              .colors
                              .themeAccentDisabled,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ArDriveTheme(
                        key: const ValueKey('turbo_payment_form'),
                        themeData: textTheme,
                        child: ArDriveTextField(
                          controller: _emailController,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ArDriveCheckBox(
                        title: 'Keep me up to date on news and promotions.',
                        titleStyle: ArDriveTypography.body.buttonNormalBold(
                          color: ArDriveTheme.of(context)
                              .themeData
                              .colors
                              .themeAccentDisabled,
                        ),
                        checked: false,
                      ),
                      const Divider(
                        height: 80,
                      ),
                      _footer(context)
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputBorder _getBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  InputBorder _getEnabledBorder(ArDriveTextFieldTheme theme) {
    // if (textFieldState == TextFieldState.success) {
    //   return _getSuccessBorder(theme);
    // } else if (textFieldState == TextFieldState.error) {
    //   return _getErrorBorder(theme);
    // }

    return _getBorder(theme.defaultBorderColor);
  }

  InputBorder _getFocusedBoder(ArDriveTextFieldTheme theme) {
    // if (textFieldState == TextFieldState.success) {
    //   return _getSuccessBorder(theme);
    // } else if (textFieldState == TextFieldState.error) {
    //   return _getErrorBorder(theme);
    // }

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

  Widget _footer(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ArDriveClickArea(
            child: GestureDetector(
              onTap: () {
                context.read<TurboTopupFlowBloc>().add(
                      TurboTopUpShowPaymentFormView(4),
                    );
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
          BlocBuilder<PaymentReviewBloc, PaymentReviewState>(
            builder: (context, state) {
              return ArDriveButton(
                maxHeight: 44,
                maxWidth: 143,
                // TODO: localize
                text: 'Pay',
                fontStyle: ArDriveTypography.body.buttonLargeBold(
                  color: Colors.white,
                ),
                isDisabled: state is PaymentReviewLoadingQuote,
                customContent: state is PaymentReviewLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
                onPressed: () async {
                  if (state is PaymentReviewLoading) {
                    return;
                  }

                  context.read<PaymentReviewBloc>().add(
                        PaymentReviewFinishPayment(
                          email: _emailController.text,
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

class RefreshButton extends StatefulWidget {
  final void Function() onPressed;

  RefreshButton({required this.onPressed});

  @override
  _RefreshButtonState createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SlideTransition(
          position: _animation,
          child: ArDriveIconButton(
            onPressed: () {
              widget.onPressed();
              _controller.forward();
            },
            size: 14,
            icon: ArDriveIcons.refresh(
              color:
                  ArDriveTheme.of(context).themeData.colors.themeAccentDisabled,
            ),
          ),
        ),
        FadeTransition(
          opacity: _controller,
          child: Text(
            'Refresh',
            style: ArDriveTypography.body.buttonNormalBold(
              color:
                  ArDriveTheme.of(context).themeData.colors.themeAccentDisabled,
            ),
          ),
        ),
      ],
    );
  }
}

class RefreshQuoteButton extends StatefulWidget {
  @override
  _RefreshQuoteButtonState createState() => _RefreshQuoteButtonState();
}

class _RefreshQuoteButtonState extends State<RefreshQuoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAndSizeAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    _fadeAndSizeAnimation =
        Tween<double>(begin: 1, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentReviewBloc, PaymentReviewState>(
      builder: (context, state) {
        if (state is PaymentReviewLoadingQuote) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        return ArDriveClickArea(
          child: GestureDetector(
            onTap: () {
              context
                  .read<PaymentReviewBloc>()
                  .add(PaymentReviewRefreshQuote());
            },
            child: Row(
              children: [
                if (state is PaymentReviewLoadingQuote)
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                if (state is! PaymentReviewLoadingQuote)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: ArDriveIcons.refresh(
                      color: ArDriveTheme.of(context)
                          .themeData
                          .colors
                          .themeAccentDisabled,
                      size: 16,
                    ),
                  ),
                SizedBox(width: 4),
                FadeTransition(
                  opacity: _fadeAndSizeAnimation,
                  child: SizeTransition(
                    sizeFactor: _fadeAndSizeAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1,
                    child: Text(
                      'Refresh',
                      style: ArDriveTypography.body.buttonNormalBold(
                        color: ArDriveTheme.of(context)
                            .themeData
                            .colors
                            .themeAccentDisabled,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
