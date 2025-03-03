import 'package:ff_annotation_route_core/ff_annotation_route_core.dart';
@FFArgumentImport()
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mikan_flutter/internal/extension.dart';
import 'package:mikan_flutter/internal/screen.dart';
import 'package:mikan_flutter/widget/sliver_pinned_header.dart';

@FFRoute(
  name: "license-detail",
  routeName: "/license/detail",
)
@immutable
class LicenseDetail extends StatefulWidget {
  const LicenseDetail({
    Key? key,
    required this.packageName,
    required this.licenseEntries,
  }) : super(key: key);

  final String packageName;
  final List<LicenseEntry> licenseEntries;

  @override
  State<LicenseDetail> createState() => _LicenseDetailState();
}

class _LicenseDetailState extends State<LicenseDetail> {
  late final _licenses = _buildLicenseLines();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion(
      value: context.fitSystemUiOverlayStyle,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPinnedTitleHeader(title: widget.packageName),
            SliverPadding(
              padding: EdgeInsets.only(
                top: 8.0,
                left: 16.0,
                right: 16.0,
                bottom: 24.0 + Screens.navBarHeight,
              ),
              sliver: FutureBuilder<List<Widget>>(
                future: _licenses,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Container(
                          height: 120.0,
                          width: 120.0,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/mikan.png",
                              ),
                              colorFilter: ColorFilter.mode(
                                Colors.grey,
                                BlendMode.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      return SliverFillRemaining(
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: theme.secondary,
                            ),
                          ),
                        ),
                      );
                    case ConnectionState.done:
                      final data = snapshot.data!;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) {
                            return data[index];
                          },
                          childCount: data.length,
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Widget>> _buildLicenseLines() async {
    final licenses = <Widget>[];
    for (final LicenseEntry license in widget.licenseEntries) {
      final List<LicenseParagraph> paragraphs =
          await SchedulerBinding.instance.scheduleTask<List<LicenseParagraph>>(
        license.paragraphs.toList,
        Priority.animation,
        debugLabel: 'License',
      );
      if (licenses.isNotEmpty) {
        licenses.add(const Padding(
          padding: EdgeInsets.all(18.0),
          child: Divider(),
        ));
      }
      for (final LicenseParagraph paragraph in paragraphs) {
        if (paragraph.indent == LicenseParagraph.centeredIndent) {
          licenses.add(Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              paragraph.text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: "mono",
                height: 1.5,
              ),
            ),
          ));
        } else {
          licenses.add(Padding(
            padding: EdgeInsetsDirectional.only(
              top: 8.0,
              start: 16.0 * paragraph.indent,
            ),
            child: Text(
              paragraph.text,
              style: const TextStyle(
                fontFamily: "mono",
                height: 1.5,
              ),
            ),
          ));
        }
      }
    }
    return licenses;
  }
}
