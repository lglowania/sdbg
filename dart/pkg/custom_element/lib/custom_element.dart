// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Custom Elements let authors define their own elements. Authors associate code
 * with custom tag names, and then use those custom tag names as they would any
 * standard tag. See <www.polymer-project.org/platform/custom-elements.html>
 * for more information.
 */
library custom_element;

import 'dart:async';
import 'dart:html';
import 'package:mdv/mdv.dart' as mdv;
import 'package:meta/meta.dart';
import 'src/custom_tag_name.dart';

// TODO(jmesserly): replace with a real custom element polyfill.
// This is just something temporary.
/**
 * *Warning*: this implementation is a work in progress. It only implements
 * the specification partially.
 *
 * Registers a custom HTML element with [localName] and the associated
 * constructor. This will ensure the element is detected and
 *
 * See the specification at:
 * <https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html>
 */
void registerCustomElement(String localName, CustomElement create()) {
  if (_customElements == null) {
    _customElements = {};
    mdv.instanceCreated.add(initCustomElements);
    // TODO(jmesserly): use MutationObserver to watch for inserts?
  }

  if (!isCustomTag(localName)) {
    throw new ArgumentError('$localName is not a valid custom element name, '
        'it should have at least one dash and not be a reserved name.');
  }

  if (_customElements.containsKey(localName)) {
    throw new ArgumentError('custom element $localName already registered.');
  }

  // TODO(jmesserly): validate this is a valid tag name, not a selector.
  _customElements[localName] = create;

  // Initialize elements already on the page.
  for (var query in [localName, '[is=$localName]']) {
    for (var element in document.queryAll(query)) {
      _initCustomElement(element, create);
    }
  }
}

/**
 * Creates a new element and returns it. If the [localName] has been registered
 * with [registerCustomElement], it will create the custom element.
 *
 * This is similar to `new Element.tag` in Dart and `document.createElement`
 * in JavaScript.
 *
 * *Warning*: this API is temporary until [dart:html] supports custom elements.
 */
Element createElement(String localName) =>
    initCustomElements(new Element.tag(localName));

/**
 * Similar to `new Element.html`, but automatically creates registed custom
 * elements.
 * *Warning*: this API is temporary until [dart:html] supports custom elements.
 */
Element createElementFromHtml(String html) =>
    initCustomElements(new Element.html(html));

/**
 * Initialize any registered custom elements recursively in the [node] tree.
 * For convenience this returns the [node] instance.
 *
 * *Warning*: this API is temporary until [dart:html] supports custom elements.
 */
Node initCustomElements(Node node) {
  for (var c = node.firstChild; c != null; c = c.nextNode) {
    initCustomElements(c);
  }
  if (node is Element) {
    var ctor = _customElements[(node as Element).localName];
    if (ctor == null) {
      var attr = (node as Element).attributes['is'];
      if (attr != null) ctor = _customElements[attr];
    }
    if (ctor != null) _initCustomElement(node, ctor);
  }
  return node;
}

/**
 * The base class for all Dart web components. In addition to the [Element]
 * interface, it also provides lifecycle methods:
 * - [created]
 * - [inserted]
 * - [attributeChanged]
 * - [removed]
 */
class CustomElement implements Element {
  /** The web component element wrapped by this class. */
  Element _host;
  List _shadowRoots;

  /**
   * Shadow roots generated by dwc for each custom element, indexed by the
   * custom element tag name.
   */
  Map<String, dynamic> _generatedRoots = {};

  /**
   * Temporary property until components extend [Element]. An element can
   * only be associated with one host, and it is an error to use a web component
   * without an associated host element.
   */
  Element get host {
    if (_host == null) throw new StateError('host element has not been set.');
    return _host;
  }

  set host(Element value) {
    if (value == null) {
      throw new ArgumentError('host must not be null.');
    }
    // TODO(jmesserly): xtag used to return "null" if unset, now it checks for
    // "this". Temporarily allow both.
    var xtag = value.xtag;
    if (xtag != null && xtag != value) {
      throw new ArgumentError('host must not have its xtag property set.');
    }
    if (_host != null) {
      throw new StateError('host can only be set once.');
    }

    value.xtag = this;
    _host = value;
  }

  /**
   * **Note**: This is an implementation helper and should not need to be called
   * from your code.
   *
   * Creates the [ShadowRoot] backing this component.
   */
  createShadowRoot([String componentName]) {
    var root = host.createShadowRoot();
    if (componentName != null) {
      _generatedRoots[componentName] = root;
    }
    return root;
  }

  getShadowRoot(String componentName) => _generatedRoots[componentName];

  /**
   * Invoked when this component gets created.
   * Note that [root] will be a [ShadowRoot] if the browser supports Shadow DOM.
   */
  void created() {}

  /** Invoked when this component gets inserted in the DOM tree. */
  void inserted() {}

  /** Invoked when this component is removed from the DOM tree. */
  void removed() {}

  // TODO(jmesserly): how do we implement this efficiently?
  // See https://github.com/dart-lang/web-ui/issues/37
  /** Invoked when any attribute of the component is modified. */
  void attributeChanged(String name, String oldValue, String newValue) {}

  get model => host.model;

  void set model(newModel) {
    host.model = newModel;
  }

  get templateInstance => host.templateInstance;
  get isTemplate => host.isTemplate;
  get ref => host.ref;
  get content => host.content;
  DocumentFragment createInstance(model, [BindingDelegate delegate]) =>
      host.createInstance(model, delegate);
  createBinding(String name, model, String path) =>
      host.createBinding(name, model, path);
  bind(String name, model, String path) => host.bind(name, model, path);
  void unbind(String name) => host.unbind(name);
  void unbindAll() => host.unbindAll();
  get bindings => host.bindings;
  BindingDelegate get bindingDelegate => host.bindingDelegate;
  set bindingDelegate(BindingDelegate value) { host.bindingDelegate = value; }

  // TODO(jmesserly): this forwarding is temporary until Dart supports
  // subclassing Elements.
  // TODO(jmesserly): we were missing the setter for title, are other things
  // missing setters?

  List<Node> get nodes => host.nodes;

  set nodes(Iterable<Node> value) { host.nodes = value; }

  /**
   * Replaces this node with another node.
   */
  Node replaceWith(Node otherNode) { host.replaceWith(otherNode); }

  /**
   * Removes this node from the DOM.
   */
  void remove() => host.remove();

  Node get nextNode => host.nextNode;

  String get nodeName => host.nodeName;

  Document get document => host.document;

  Node get previousNode => host.previousNode;

  String get text => host.text;

  set text(String v) { host.text = v; }

  bool contains(Node other) => host.contains(other);

  bool hasChildNodes() => host.hasChildNodes();

  Node insertBefore(Node newChild, Node refChild) =>
    host.insertBefore(newChild, refChild);

  Node insertAllBefore(Iterable<Node> newChild, Node refChild) =>
    host.insertAllBefore(newChild, refChild);

  Map<String, String> get attributes => host.attributes;
  set attributes(Map<String, String> value) {
    host.attributes = value;
  }

  List<Element> get elements => host.children;

  set elements(List<Element> value) {
    host.children = value;
  }

  List<Element> get children => host.children;

  set children(List<Element> value) {
    host.children = value;
  }

  Set<String> get classes => host.classes;

  set classes(Iterable<String> value) {
    host.classes = value;
  }

  CssRect get contentEdge => host.contentEdge;
  CssRect get paddingEdge => host.paddingEdge;
  CssRect get borderEdge => host.borderEdge;
  CssRect get marginEdge => host.marginEdge;
  Point get documentOffset => host.documentOffset;
  Point offsetTo(Element parent) => host.offsetTo(parent);

  Map<String, String> getNamespacedAttributes(String namespace) =>
      host.getNamespacedAttributes(namespace);

  CssStyleDeclaration getComputedStyle([String pseudoElement])
    => host.getComputedStyle(pseudoElement);

  Element clone(bool deep) => host.clone(deep);

  Element get parent => host.parent;

  Node get parentNode => host.parentNode;

  String get nodeValue => host.nodeValue;

  @deprecated
  // TODO(sigmund): restore the old return type and call host.on when
  // dartbug.com/8131 is fixed.
  dynamic get on { throw new UnsupportedError('on is deprecated'); }

  String get contentEditable => host.contentEditable;
  set contentEditable(String v) { host.contentEditable = v; }

  String get dir => host.dir;
  set dir(String v) { host.dir = v; }

  bool get draggable => host.draggable;
  set draggable(bool v) { host.draggable = v; }

  bool get hidden => host.hidden;
  set hidden(bool v) { host.hidden = v; }

  String get id => host.id;
  set id(String v) { host.id = v; }

  String get innerHTML => host.innerHtml;

  void set innerHTML(String v) {
    host.innerHtml = v;
  }

  String get innerHtml => host.innerHtml;
  void set innerHtml(String v) {
    host.innerHtml = v;
  }

  InputMethodContext get inputMethodContext => host.inputMethodContext;

  bool get isContentEditable => host.isContentEditable;

  String get lang => host.lang;
  set lang(String v) { host.lang = v; }

  String get outerHtml => host.outerHtml;

  bool get spellcheck => host.spellcheck;
  set spellcheck(bool v) { host.spellcheck = v; }

  int get tabIndex => host.tabIndex;
  set tabIndex(int i) { host.tabIndex = i; }

  String get title => host.title;

  set title(String value) { host.title = value; }

  bool get translate => host.translate;
  set translate(bool v) { host.translate = v; }

  String get dropzone => host.dropzone;
  set dropzone(String v) { host.dropzone = v; }

  void click() { host.click(); }

  List<Node> getDestinationInsertionPoints() =>
    host.getDestinationInsertionPoints();

  Element insertAdjacentElement(String where, Element element) =>
    host.insertAdjacentElement(where, element);

  void insertAdjacentHtml(String where, String html) {
    host.insertAdjacentHtml(where, html);
  }

  void insertAdjacentText(String where, String text) {
    host.insertAdjacentText(where, text);
  }

  Map<String, String> get dataset => host.dataset;

  set dataset(Map<String, String> value) {
    host.dataset = value;
  }

  Element get nextElementSibling => host.nextElementSibling;

  Element get offsetParent => host.offsetParent;

  Element get previousElementSibling => host.previousElementSibling;

  CssStyleDeclaration get style => host.style;

  String get tagName => host.tagName;

  String get pseudo => host.pseudo;

  void set pseudo(String value) {
    host.pseudo = value;
  }

  // Note: we are not polyfilling the shadow root here. This will be fixed when
  // we migrate to the JS Shadow DOM polyfills. You can still use getShadowRoot
  // to retrieve a node that behaves as the shadow root when Shadow DOM is not
  // enabled.
  ShadowRoot get shadowRoot => host.shadowRoot;

  void blur() { host.blur(); }

  void focus() { host.focus(); }

  void scrollByLines(int lines) {
    host.scrollByLines(lines);
  }

  void scrollByPages(int pages) {
    host.scrollByPages(pages);
  }

  void scrollIntoView([ScrollAlignment alignment]) {
    host.scrollIntoView(alignment);
  }

  bool matches(String selectors) => host.matches(selectors);

  bool matchesWithAncestors(String selectors) =>
      host.matchesWithAncestors(selectors);

  @deprecated
  void requestFullScreen(int flags) { requestFullscreen(); }

  void requestFullscreen() { host.requestFullscreen(); }

  void requestPointerLock() { host.requestPointerLock(); }

  Element query(String selectors) => host.query(selectors);

  ElementList queryAll(String selectors) => host.queryAll(selectors);

  String get className => host.className;
  set className(String value) { host.className = value; }

  @deprecated
  int get clientHeight => client.height;

  @deprecated
  int get clientLeft => client.left;

  @deprecated
  int get clientTop => client.top;

  @deprecated
  int get clientWidth => client.width;

  Rect get client => host.client;

  @deprecated
  int get offsetHeight => offset.height;

  @deprecated
  int get offsetLeft => offset.left;

  @deprecated
  int get offsetTop => offset.top;

  @deprecated
  int get offsetWidth => offset.width;

  Rect get offset => host.offset;

  int get scrollHeight => host.scrollHeight;

  int get scrollLeft => host.scrollLeft;

  int get scrollTop => host.scrollTop;

  set scrollLeft(int value) { host.scrollLeft = value; }

  set scrollTop(int value) { host.scrollTop = value; }

  int get scrollWidth => host.scrollWidth;

  String $dom_getAttribute(String name) =>
      host.$dom_getAttribute(name);

  String $dom_getAttributeNS(String namespaceUri, String localName) =>
      host.$dom_getAttributeNS(namespaceUri, localName);

  String $dom_setAttributeNS(
      String namespaceUri, String localName, String value) {
    host.$dom_setAttributeNS(namespaceUri, localName, value);
  }

  Rect getBoundingClientRect() => host.getBoundingClientRect();

  List<Rect> getClientRects() => host.getClientRects();

  List<Node> getElementsByClassName(String name) =>
      host.getElementsByClassName(name);

  void $dom_setAttribute(String name, String value) =>
      host.$dom_setAttribute(name, value);

  List<Node> get $dom_childNodes => host.$dom_childNodes;

  Node get firstChild => host.firstChild;

  Node get lastChild => host.lastChild;

  String get localName => host.localName;

  String get namespaceUri => host.namespaceUri;

  int get nodeType => host.nodeType;

  void $dom_addEventListener(String type, EventListener listener,
                             [bool useCapture]) {
    host.$dom_addEventListener(type, listener, useCapture);
  }

  bool dispatchEvent(Event event) => host.dispatchEvent(event);

  void $dom_removeEventListener(String type, EventListener listener,
                                [bool useCapture]) {
    host.$dom_removeEventListener(type, listener, useCapture);
  }

  get xtag => host.xtag;

  set xtag(value) { host.xtag = value; }

  Node append(Node e) => host.append(e);

  void appendText(String text) => host.appendText(text);

  void appendHtml(String html) => host.appendHtml(html);

  String get regionOverset => host.regionOverset;

  List<Range> getRegionFlowRanges() => host.getRegionFlowRanges();

  // TODO(jmesserly): rename "created" to "onCreated".
  void onCreated() => created();

  Stream<Event> get onAbort => host.onAbort;
  Stream<Event> get onBeforeCopy => host.onBeforeCopy;
  Stream<Event> get onBeforeCut => host.onBeforeCut;
  Stream<Event> get onBeforePaste => host.onBeforePaste;
  Stream<Event> get onBlur => host.onBlur;
  Stream<Event> get onChange => host.onChange;
  Stream<MouseEvent> get onClick => host.onClick;
  Stream<MouseEvent> get onContextMenu => host.onContextMenu;
  Stream<Event> get onCopy => host.onCopy;
  Stream<Event> get onCut => host.onCut;
  Stream<Event> get onDoubleClick => host.onDoubleClick;
  Stream<MouseEvent> get onDrag => host.onDrag;
  Stream<MouseEvent> get onDragEnd => host.onDragEnd;
  Stream<MouseEvent> get onDragEnter => host.onDragEnter;
  Stream<MouseEvent> get onDragLeave => host.onDragLeave;
  Stream<MouseEvent> get onDragOver => host.onDragOver;
  Stream<MouseEvent> get onDragStart => host.onDragStart;
  Stream<MouseEvent> get onDrop => host.onDrop;
  Stream<Event> get onError => host.onError;
  Stream<Event> get onFocus => host.onFocus;
  Stream<Event> get onInput => host.onInput;
  Stream<Event> get onInvalid => host.onInvalid;
  Stream<KeyboardEvent> get onKeyDown => host.onKeyDown;
  Stream<KeyboardEvent> get onKeyPress => host.onKeyPress;
  Stream<KeyboardEvent> get onKeyUp => host.onKeyUp;
  Stream<Event> get onLoad => host.onLoad;
  Stream<MouseEvent> get onMouseDown => host.onMouseDown;
  Stream<MouseEvent> get onMouseEnter => host.onMouseEnter;
  Stream<MouseEvent> get onMouseLeave => host.onMouseLeave;
  Stream<MouseEvent> get onMouseMove => host.onMouseMove;
  Stream<Event> get onFullscreenChange => host.onFullscreenChange;
  Stream<Event> get onFullscreenError => host.onFullscreenError;
  Stream<Event> get onPaste => host.onPaste;
  Stream<Event> get onReset => host.onReset;
  Stream<Event> get onScroll => host.onScroll;
  Stream<Event> get onSearch => host.onSearch;
  Stream<Event> get onSelect => host.onSelect;
  Stream<Event> get onSelectStart => host.onSelectStart;
  Stream<Event> get onSubmit => host.onSubmit;
  Stream<MouseEvent> get onMouseOut => host.onMouseOut;
  Stream<MouseEvent> get onMouseOver => host.onMouseOver;
  Stream<MouseEvent> get onMouseUp => host.onMouseUp;
  Stream<TouchEvent> get onTouchCancel => host.onTouchCancel;
  Stream<TouchEvent> get onTouchEnd => host.onTouchEnd;
  Stream<TouchEvent> get onTouchEnter => host.onTouchEnter;
  Stream<TouchEvent> get onTouchLeave => host.onTouchLeave;
  Stream<TouchEvent> get onTouchMove => host.onTouchMove;
  Stream<TouchEvent> get onTouchStart => host.onTouchStart;
  Stream<TransitionEvent> get onTransitionEnd => host.onTransitionEnd;

  // TODO(sigmund): do the normal forwarding when dartbug.com/7919 is fixed.
  Stream<WheelEvent> get onMouseWheel {
    throw new UnsupportedError('onMouseWheel is not supported');
  }
}


Map<String, Function> _customElements;

void _initCustomElement(Element node, CustomElement ctor()) {
  CustomElement element = ctor();
  element.host = node;

  // TODO(jmesserly): replace lifecycle stuff with a proper polyfill.
  element.created();

  _registerLifecycleInsert(element);
}

void _registerLifecycleInsert(CustomElement element) {
  runAsync(() {
    // TODO(jmesserly): bottom up or top down insert?
    var node = element.host;

    // TODO(jmesserly): need a better check to see if the node has been removed.
    if (node.parentNode == null) return;

    _registerLifecycleRemove(element);
    element.inserted();
  });
}

void _registerLifecycleRemove(CustomElement element) {
  // TODO(jmesserly): need fallback or polyfill for MutationObserver.
  if (!MutationObserver.supported) return;

  new MutationObserver((records, observer) {
    var node = element.host;
    for (var record in records) {
      for (var removed in record.removedNodes) {
        if (identical(node, removed)) {
          observer.disconnect();
          element.removed();
          return;
        }
      }
    }
  }).observe(element.parentNode, childList: true);
}
