library scoped_model;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Finds a [Model]. Deprecated: Use [ScopedModel.of] instead.
@deprecated
class ModelFinder<T extends ValueNotifier> {
  /// Returns the [Model] of type [T] of the closest ancestor [ScopedModel].
  ///
  /// [Widget]s who call [of] with a [rebuildOnChange] of true will be rebuilt
  /// whenever there's a change to the returned model.
  T of(BuildContext context, {bool rebuildOnChange = false}) {
    return ScopedModel.of<T>(context, rebuildOnChange: rebuildOnChange);
  }
}

/// Provides a [Model] to all descendants of this Widget.
///
/// Descendant Widgets can access the model by using the
/// [ScopedModelDescendant] Widget, which rebuilds each time the model changes,
/// or directly via the [ScopedModel.of] static method.
///
/// To provide a Model to all screens, place the [ScopedModel] Widget above the
/// [WidgetsApp] or [MaterialApp] in the Widget tree.
///
/// ### Example
///
/// ```
/// ScopedModel<CounterModel>(
///   model: CounterModel(),
///   child: ScopedModelDescendant<CounterModel>(
///     builder: (context, child, model) => Text(model.counter.toString()),
///   ),
/// );
/// ```
class ScopedModel<T extends ValueNotifier> extends StatelessWidget {
  /// The [Model] to provide to [child] and its descendants.
  final T model;

  /// The [Widget] the [model] will be available to.
  final Widget child;

  ScopedModel({@required this.model, @required this.child})
      : assert(model != null),
        assert(child != null);

  @override
  Widget build(BuildContext context) {
    return _InheritedModel<T>(model: model, child: child);
  }

  /// Finds a [Model] provided by a [ScopedModel] Widget.
  ///
  /// Generally, you'll use a [ScopedModelDescendant] to access a model in the
  /// Widget tree and rebuild when the model changes. However, if you would to
  /// access the model directly, you can use this function instead!
  ///
  /// ### Example
  ///
  /// ```
  /// final model = ScopedModel.of<CounterModel>();
  /// ```
  ///
  /// If you find yourself accessing your Model multiple times in this way, you
  /// could also consider adding a convenience method to your own Models.
  ///
  /// ### Model Example
  ///
  /// ```
  /// class CounterModel extends Model {
  ///   static CounterModel of(BuildContext context) =>
  ///       ScopedModel.of<CounterModel>(context);
  /// }
  ///
  /// // Usage
  /// final model = CounterModel.of(context);
  /// ```
  ///
  /// ## Listening to multiple Models
  ///
  /// If you want a single Widget to rely on multiple models, you can use the
  /// `of` method! No need to manage subscriptions, Flutter takes care of all
  ///  of that through the magic of InheritedWidgets.
  ///
  /// ```
  /// class CombinedWidget extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final username =
  ///       ScopedModel.of<UserModel>(context, rebuildOnChange: true).username;
  ///     final counter =
  ///       ScopedModel.of<CounterModel>(context, rebuildOnChange: true).counter;
  ///
  ///     return Text('$username tapped the button $counter times');
  ///   }
  /// }
  /// ```
  static T of<T extends ValueNotifier>(
    BuildContext context, {
    bool rebuildOnChange = false,
  }) {
    final Type type = _type<_InheritedModel<T>>();

    Widget widget = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(type)
        : context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;

    if (widget == null) {
      throw ScopedModelError();
    } else {
      return (widget as _InheritedModel<T>).model;
    }
  }

  static Type _type<T>() => T;
}

/// Provides [model] to its [child] [Widget] tree via [InheritedWidget].  When
/// [version] changes, all descendants who request (via
/// [BuildContext.inheritFromWidgetOfExactType]) to be rebuilt when the model
/// changes will do so.
class _InheritedModel<T extends ValueNotifier> extends InheritedWidget {
  final T model;

  _InheritedModel({Key key, Widget child, T model})
      : this.model = model,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedModel<T> oldWidget) => true;
}

/// Builds a child for a [ScopedModelDescendant].
typedef Widget ScopedModelDescendantBuilder<T extends ValueNotifier>(
  BuildContext context,
  Widget child,
  T model,
);

/// Finds a specific [Model] provided by a [ScopedModel] Widget and rebuilds
/// whenever the [Model] changes.
///
/// Provides an option to disable rebuilding when the [Model] changes.
///
/// Provide a constant [child] Widget if some portion inside the builder does
/// not rely on the [Model] and should not be rebuilt.
///
/// ### Example
///
/// ```
/// ScopedModel<CounterModel>(
///   model: CounterModel(),
///   child: ScopedModelDescendant<CounterModel>(
///     child: Text('Button has been pressed:'),
///     builder: (context, child, model) {
///       return Column(
///         children: [
///           child,
///           Text('${model.counter}'),
///         ],
///       );
///     }
///   ),
/// );
/// ```
class ScopedModelDescendant<T extends ValueNotifier> extends StatelessWidget {
  /// Builds a Widget when the Widget is first created and whenever
  /// the [Model] changes if [rebuildOnChange] is set to `true`.
  final ScopedModelDescendantBuilder<T> builder;

  /// An optional constant child that does not depend on the model.  This will
  /// be passed as the child of [builder].
  final Widget child;

  /// An optional value that determines whether the Widget will rebuild when
  /// the model changes.
  final bool rebuildOnChange;

  /// Creates the ScopedModelDescendant
  ScopedModelDescendant({
    @required this.builder,
    this.child,
    this.rebuildOnChange = true,
  });

  @override
  Widget build(BuildContext context) {
    final model = ScopedModel.of<T>(context, rebuildOnChange: rebuildOnChange);
    return ValueListenableBuilder(
      valueListenable: model,
      child: child,
      builder: (context, _value, child) {
        return builder(
          context,
          child,
          model,
        );
      },
    );
  }
}

/// The error that will be thrown if the ScopedModel cannot be found in the
/// Widget tree.
class ScopedModelError extends Error {
  ScopedModelError();

  String toString() {
    return '''Error: Could not find the correct ScopedModel.

To fix, please:

  * Provide types to ScopedModel<MyModel>
  * Provide types to ScopedModelDescendant<MyModel>
  * Provide types to ScopedModel.of<MyModel>()
  * Always use package imports. Ex: `import 'package:my_app/my_model.dart';

If none of these solutions work, please file a bug at:
https://github.com/brianegan/scoped_model/issues/new
      ''';
  }
}
