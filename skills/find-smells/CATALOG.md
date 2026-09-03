# Smell Catalog

The 22 smells from <https://refactoring.guru/refactoring/smells>, in the
five groups of the site. Each smell has four lines.

- **Signs.** What the code looks like. The code must match this line.
- **Fix.** The techniques the site prescribes, with the condition that
  selects each one. Every technique has a page at
  `https://refactoring.guru/<slug>`. The slug is the technique name in kebab
  case, for example <https://refactoring.guru/extract-method>.
- **Ignore.** When the site says to leave it. Report these in the *Seen and
  ignored* table, not as findings.
- **Languages.** How the smell looks in Go, Rust, TypeScript, Python, and
  Bash. "Class" means struct, impl block, module, or object in a language
  without classes. Skip a smell where the note says it does not apply.

For a document such as a skill folder or a docs tree, read a file as a
class, a section or a numbered step as a method, and a link or a pointer to
another file as a call. A rule stated in two files is Duplicate Code.

Each smell heading below links to its page on the site.

## Group 1: Bloaters

Code that grew so large that it is hard to work with.

### Long Method

<https://refactoring.guru/smells/long-method>

- **Signs.** The site says any method over ten lines deserves a question.
  Flag a function over about 30 lines, or with nesting deeper than three.
  Quote the site number in the finding.
- **Fix.** Extract Method for most cases. Replace Temp with Query when local
  variables block the extraction. Introduce Parameter Object or Preserve Whole
  Object when parameters block it. Replace Method with Method Object when the
  three above fail. Decompose Conditional for a long `if` chain.
- **Ignore.** The site gives no ignore case. A flat table of data is not a
  long method.
- **Languages.** All. In Bash, a function over 30 lines with nested `if` and
  `for` is the same smell. In Go, a long `main` that also parses flags and
  runs the server counts.

### Large Class

<https://refactoring.guru/smells/large-class>

- **Signs.** A class with many fields, many methods, or many lines.
- **Fix.** Extract Class when a subset of fields and methods form one idea.
  Extract Subclass when a behaviour is rare or has variants. Extract Interface
  when a client needs only a few operations. Duplicate Observed Data for a GUI
  class that holds domain data.
- **Ignore.** The site gives no ignore case.
- **Languages.** In Go and Rust, look at a struct with many fields and a long
  list of methods on it. In Go, a package with one file that holds every type
  counts. In Python and TypeScript, a module with one giant class counts.
  Bash: a script with no functions over about 200 lines.

### Primitive Obsession

<https://refactoring.guru/smells/primitive-obsession>

- **Signs.** A primitive where a small type belongs. Money as `float`, a
  range as two ints, a phone number as `string`. Constants such as
  `ROLE_ADMIN = 1`. String keys into a map used as a record.
- **Fix.** Replace Data Value with Object for a group of primitive fields.
  Introduce Parameter Object or Preserve Whole Object when they travel as
  parameters. Replace Type Code with Class, with Subclasses, or with
  State/Strategy for a coded value. Replace Array with Object for an array
  used as a record.
- **Ignore.** The site gives no ignore case.
- **Languages.** Go: a bare `string` or `int` where a named type fits, and a
  `map[string]interface{}` used as a record. Rust: a bare `String` where a
  newtype fits, and `(i64, i64)` where a struct fits. TypeScript: a plain
  object type where a class or branded type fits. Python: a dict used as a
  record where a dataclass fits. Bash: does not apply.

### Long Parameter List

<https://refactoring.guru/smells/long-parameter-list>

- **Signs.** More than three or four parameters.
- **Fix.** Replace Parameter with Method Call when the caller computes a
  parameter from an object it already has. Preserve Whole Object when several
  parameters come from one object. Introduce Parameter Object when they come
  from different places.
- **Ignore.** When the removal adds a dependency between two classes that
  should not know each other.
- **Languages.** All. Go: `ctx` and `error` do not count. A functional
  options struct is the fix for a constructor. Rust: a builder is the fix for
  a constructor. Bash: a function that reads `$1` to `$6` counts.

### Data Clumps

<https://refactoring.guru/smells/data-clumps>

- **Signs.** The same group of variables in several places. Host, port, user,
  and password. Start and end. The test: remove one, and the rest lose their
  meaning.
- **Fix.** Extract Class when the clump is a set of fields. Introduce
  Parameter Object when it is a set of parameters. Preserve Whole Object when
  the clump is passed on to other methods. Then Move Method to bring the code
  that works on the clump into the new class.
- **Ignore.** When passing a whole object adds a dependency that you do not
  want.
- **Languages.** All. Go: three parameters that always travel together want a
  struct. Bash: three global variables that always change together want a
  single config file or associative array.

## Group 2: Object-Orientation Abusers

Wrong or incomplete use of object-oriented ideas.

### Alternative Classes with Different Interfaces

<https://refactoring.guru/smells/alternative-classes-with-different-interfaces>

- **Signs.** Two classes do the same job with different method names.
- **Fix.** Rename Method to align the names. Move Method, Add Parameter, and
  Parameterize Method to align the signatures. Extract Superclass when only
  part of the job is shared. Then delete the extra class.
- **Ignore.** When the two classes live in different libraries that you do
  not own.
- **Languages.** Go: two types that should share one interface but do not.
  Rust: two types that should share one trait. TypeScript and Python: two
  classes or modules with the same job. Bash: two scripts that do the same
  thing with different flags.

### Refused Bequest

<https://refactoring.guru/smells/refused-bequest>

- **Signs.** A subclass uses only some of what it inherits. It leaves methods
  unused or overrides them to throw.
- **Fix.** Replace Inheritance with Delegation when the classes share nothing
  in meaning. Extract Superclass when the inheritance is right but the parent
  carries extra.
- **Ignore.** The site gives no ignore case.
- **Languages.** Go: a struct that embeds another only to reuse one method,
  and then shadows the rest. Rust: a trait impl that returns `unimplemented!`
  for half the methods. TypeScript and Python: as written. Bash: does not
  apply.

### Switch Statements

<https://refactoring.guru/smells/switch-statements>

- **Signs.** A complex `switch`, or a chain of `if` on the same value, that
  repeats in more than one place.
- **Fix.** Extract Method then Move Method to put the switch in the right
  class. Replace Type Code with Subclasses or with State/Strategy when the
  switch is on a type code. Then Replace Conditional with Polymorphism.
  Replace Parameter with Explicit Methods when each branch calls one method
  with a different argument. Introduce Null Object when one branch handles
  `null`.
- **Ignore.** A switch that does one simple thing and does not grow. A switch
  inside a Factory Method or Abstract Factory.
- **Languages.** Go: the same `switch` on a kind field or a type switch in
  several packages. The fix is an interface. Rust: a `match` on an enum is
  the normal way to write a sum type. Report it only when the same `match`
  repeats in several places. The fix is a trait or a method on the enum.
  TypeScript: a discriminated union with one `switch` is fine. Bash: a `case`
  block is the normal way to dispatch. Report it only when it repeats.

### Temporary Field

<https://refactoring.guru/smells/temporary-field>

- **Signs.** A field that holds a value only during one operation and is
  empty the rest of the time.
- **Fix.** Extract Class to move the field and the code that uses it into a
  method object. Introduce Null Object when code checks the field for
  emptiness.
- **Ignore.** The site gives no ignore case.
- **Languages.** Go: a struct field set in one method and read in another,
  with `nil` elsewhere. Rust: an `Option<T>` field that is `Some` for one
  call only. Bash: a global set in one function for another function to read.

## Group 3: Change Preventers

One change here means many changes there.

### Divergent Change

<https://refactoring.guru/smells/divergent-change>

- **Signs.** One class changes for many different reasons. A new product
  type touches the find, the display, and the order methods of one class.
- **Fix.** Extract Class to split the class by reason to change. Extract
  Superclass or Extract Subclass when several classes share one of the
  behaviours.
- **Ignore.** The site gives no ignore case.
- **Languages.** All. Use `git log --follow` on the file. Many commits with
  unrelated subjects are the evidence. Bash: one script that both builds and
  deploys.

### Parallel Inheritance Hierarchies

<https://refactoring.guru/smells/parallel-inheritance-hierarchies>

- **Signs.** A new subclass of A always needs a new subclass of B.
- **Fix.** Make instances of one hierarchy refer to instances of the other.
  Then Move Method and Move Field to remove the second hierarchy.
- **Ignore.** When the parallel shape avoids a worse design. Revert when the
  merged code is uglier.
- **Languages.** Go and Rust: a new type always needs a matching new
  handler, repository, or serializer type. TypeScript and Python: as written.
  Bash: does not apply.

### Shotgun Surgery

<https://refactoring.guru/smells/shotgun-surgery>

- **Signs.** One change needs many small edits in many classes.
- **Fix.** Move Method and Move Field to bring the pieces into one class.
  Create the class when none fits. Inline Class for a class left empty.
- **Ignore.** The site gives no ignore case.
- **Languages.** All. Grep for a constant or a field name. A hit in five
  files that all change together is the evidence. Bash: a value repeated in
  several scripts.

## Group 4: Dispensables

Code whose absence makes the rest cleaner.

### Comments

<https://refactoring.guru/smells/comments>

- **Signs.** A method full of comments that explain what the code does.
- **Fix.** Extract Variable when a comment explains an expression. Extract
  Method when a comment explains a block. Name the method after the comment.
  Rename Method when the name still needs a comment. Introduce Assertion when
  the comment states a condition that must hold.
- **Ignore.** A comment that explains *why*. A comment on an algorithm that
  has no simpler form.
- **Languages.** All. Go: a doc comment on an exported symbol is required and
  is not a smell. Rust: the same for `///` on public items. Bash: a comment
  above each block of a script is the smell. The fix is a function per
  block.

### Duplicate Code

<https://refactoring.guru/smells/duplicate-code>

- **Signs.** Two fragments that look almost the same.
- **Fix.** Extract Method for the same code in one class. Extract Method then
  Pull Up Field for sibling subclasses. Pull Up Constructor Body when it is
  in the constructors. Form Template Method when the code is similar but not
  the same. Substitute Algorithm when the result is the same and the steps
  differ. Extract Superclass for unrelated classes. Extract Class when a
  hierarchy does not fit. Consolidate Conditional Expression then Extract
  Method for several conditions with the same body. Consolidate Duplicate
  Conditional Fragments for the same code in every branch.
- **Ignore.** When the merge makes the code harder to read.
- **Languages.** All. Go: the same loop over an error check in several
  functions. Generics or a helper function is the fix. Rust: a macro or a
  generic function is the fix. Bash: the same five-line block in several
  scripts wants a shared file that they `source`.

### Data Class

<https://refactoring.guru/smells/data-class>

- **Signs.** A class with only fields and getters and setters. Other code does
  all the work on its data.
- **Fix.** Encapsulate Field for public fields. Encapsulate Collection for a
  collection field. Move Method and Extract Method to bring the client code
  into the class. Remove Setting Method and Hide Method when the class no
  longer needs them.
- **Ignore.** The site gives no ignore case. A DTO at a wire boundary is one
  by design. Say so and skip it.
- **Languages.** Go: a struct whose fields other packages read and compute on.
  The fix is a method on the struct. Rust: the same for a struct with only
  `pub` fields. TypeScript: an interface that every caller re-validates.
  Python: a dataclass that every caller re-validates. Bash: does not apply.

### Dead Code

<https://refactoring.guru/smells/dead-code>

- **Signs.** A variable, parameter, field, method, or class that nothing uses.
- **Fix.** Delete it. Inline Class or Collapse Hierarchy for an unused class
  or level. Remove Parameter for an unused parameter.
- **Ignore.** The site gives no ignore case. Check exported symbols with a
  grep across the repo first. A public API has callers that you cannot see.
- **Languages.** Go: `staticcheck` and `go vet` find most of it. Rust: the
  compiler warns on it. TypeScript: `noUnusedLocals` finds locals. Python:
  `ruff` finds it. Bash: a function that no line calls.

### Lazy Class

<https://refactoring.guru/smells/lazy-class>

- **Signs.** A class that does too little to earn its place.
- **Fix.** Inline Class when it is near useless. Collapse Hierarchy for a
  subclass with almost nothing in it.
- **Ignore.** When the class marks a planned extension. Keep the balance
  between clarity and size.
- **Languages.** Go: a package with one tiny type, or a struct that wraps one
  field and adds nothing. Rust: a newtype with no methods and no invariant.
  Bash: a one-line function called once.

### Speculative Generality

<https://refactoring.guru/smells/speculative-generality>

- **Signs.** An unused class, method, field, or parameter that exists for a
  future that never came.
- **Fix.** Collapse Hierarchy for an abstract class with one child. Inline
  Class for a delegation with no second target. Inline Method for a method
  with one caller and no meaning. Remove Parameter for an unused parameter.
  Delete an unused field.
- **Ignore.** A framework or library whose users need the extra shape. A
  hook that tests need.
- **Languages.** Go: an interface with one implementation and no test
  double. Rust: a generic parameter with one concrete type. TypeScript and
  Python: an abstract base with one subclass. Bash: a flag that nothing
  passes.

## Group 5: Couplers

Too much coupling between classes, or too much delegation.

### Feature Envy

<https://refactoring.guru/smells/feature-envy>

- **Signs.** A method reads the data of another object more than its own.
- **Fix.** Move Method when the whole method belongs elsewhere. Extract
  Method then Move Method when only part of it does. When it reads several
  classes, split it and move each part to the class it reads most.
- **Ignore.** When the split is on purpose, as in Strategy or Visitor.
- **Languages.** Go: a function in package A that reads five fields of a
  struct from package B. Rust: a free function that reads a struct it does
  not own. Bash: does not apply.

### Inappropriate Intimacy

<https://refactoring.guru/smells/inappropriate-intimacy>

- **Signs.** One class reaches into the private fields and methods of
  another.
- **Fix.** Move Method and Move Field when the parts belong where they are
  used. Extract Class and Hide Delegate to make the relation explicit. Change
  Bidirectional Association to Unidirectional when each class needs the
  other. Replace Delegation with Inheritance when it is between a child and
  its parent.
- **Ignore.** The site gives no ignore case.
- **Languages.** Go: two types in one package that read each other's
  unexported fields. Rust: `pub(crate)` fields read from many modules.
  TypeScript: `private` bypassed through `any` or bracket access. Python: a
  leading underscore name read from another module. Bash: does not apply.

### Incomplete Library Class

<https://refactoring.guru/smells/incomplete-library-class>

- **Signs.** A library lacks a method that you need, and you cannot change
  the library.
- **Fix.** Introduce Foreign Method for one or two methods. Introduce Local
  Extension for a whole set.
- **Ignore.** When the extension must change every time the library changes.
- **Languages.** Go: a helper function that takes the library type as its
  first argument is the foreign method. Rust: an extension trait is the local
  extension. TypeScript and Python: a wrapper class or a helper module. Bash:
  a wrapper function around a command.

### Message Chains

<https://refactoring.guru/smells/message-chains>

- **Signs.** A chain such as `a.b().c().d()`. The client depends on every
  hop.
- **Fix.** Hide Delegate to remove the chain. Extract Method to name what the
  chain fetches, then Move Method to put it at the start of the chain.
- **Ignore.** When hiding every delegate creates a Middle Man.
- **Languages.** All. Go: `cfg.Server().Listener().Addr().Port()`. A builder
  or fluent API is not a message chain. Rust: a chain of iterator adapters
  is not a message chain. Bash: does not apply.

### Middle Man

<https://refactoring.guru/smells/middle-man>

- **Signs.** A class that does one thing: forward the call to another class.
- **Fix.** Remove Middle Man when most of its methods delegate.
- **Ignore.** A Proxy or a Decorator by design. A class kept to avoid a
  dependency between two others.
- **Languages.** Go: a struct that embeds another and adds nothing, or a
  service type whose methods each call one repository method. Rust: a wrapper
  that only forwards. TypeScript and Python: as written. Bash: a function
  that only calls one other function with the same arguments.
