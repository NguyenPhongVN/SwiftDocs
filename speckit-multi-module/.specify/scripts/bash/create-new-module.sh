#!/usr/bin/env bash
# create-new-module.sh <Name> — scaffold a new module in the isowords-style
# single-manifest layout (see ARCHITECTURE.md §8):
#   Sources/<Name>/        module sources (skeleton varies by suffix)
#   Tests/<Name>Tests/     mirrored test target
# Then prints the Package.swift snippet to paste under the correct // MARK: group.
# Skeletons use sed -i '' (macOS/BSD sed, the platform for Swift development).
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: create-new-module.sh <ModuleName>" >&2
  echo "  ModuleName must be PascalCase, e.g. HomeFeature, ApiClient, GameCore" >&2
  exit 1
fi

NAME="$1"
if ! printf '%s' "$NAME" | grep -qE '^[A-Z][A-Za-z0-9]*$'; then
  echo "Error: '$NAME' must be PascalCase (letters and digits, starting uppercase)." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
cd "$REPO_ROOT"

SRC_DIR="Sources/$NAME"
TEST_DIR="Tests/${NAME}Tests"
mkdir -p "$SRC_DIR" "$TEST_DIR"

# Skeleton type by suffix: *Feature/*Core → TCA reducer+view (engine), *Client →
# dependency client, *Live → live implementation, anything else → plain module.
case "$NAME" in
  *Feature|*Core) MODE="feature" ;;
  *Client) MODE="client" ;;
  *Live) MODE="live" ;;
  *) MODE="plain" ;;
esac

# The reducer/view type drops the module suffix (Constitution IV): Home in
# HomeFeature, Game in GameCore. Only the *Feature skeleton uses this.
BASE="$NAME"
BASE="${BASE%Feature}"
BASE="${BASE%Core}"
if [ -z "$BASE" ]; then
  BASE="$NAME"
fi

SRC_FILE="$SRC_DIR/$NAME.swift"
if [ ! -e "$SRC_FILE" ]; then
  case "$MODE" in
    feature)
      cat > "$SRC_FILE" <<'EOF'
import ComposableArchitecture
import SwiftUI

// The reducer/view type drops the module suffix (Constitution IV):
// BASE_PLACEHOLDER lives in the NAME_PLACEHOLDER module.
@Reducer
public struct BASE_PLACEHOLDER {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case onAppear
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      }
    }
  }
}

public struct BASE_PLACEHOLDERView: View {
  @Bindable var store: StoreOf<BASE_PLACEHOLDER>
  public init(store: StoreOf<BASE_PLACEHOLDER>) {
    self.store = store
  }
  public var body: some View {
    Text("BASE_PLACEHOLDER")
  }
}
EOF
      ;;
    client)
      cat > "$SRC_FILE" <<'EOF'
import Dependencies

@DependencyClient
public struct NAME_PLACEHOLDER {
  // Declare the interface's methods as stored closures, e.g.:
  // public var fetch: @Sendable () async throws -> [Item]
}

extension NAME_PLACEHOLDER: TestDependencyKey {
  public static let testValue = NAME_PLACEHOLDER()
}

extension NAME_PLACEHOLDER: DependencyKey {
  public static var liveValue: NAME_PLACEHOLDER { .live }
}

extension NAME_PLACEHOLDER {
  public static let mock = NAME_PLACEHOLDER()
}
EOF
      ;;
    live)
      cat > "$SRC_FILE" <<'EOF'
// Live implementation module. Must be linked ONLY by the app shell, which
// injects it — features never import this module (ARCHITECTURE.md §4.3).

// import NAME_PLACEHOLDER  // ← the *Client interface this implements

// extension NAME_PLACEHOLDER {
//   public static var live: Self {
//     .init()
//   }
// }
EOF
      ;;
    plain)
      cat > "$SRC_FILE" <<'EOF'
// NAME_PLACEHOLDER — plain module. Keep the public surface minimal:
// the module boundary is the API boundary (Constitution VII).
EOF
      ;;
  esac
  sed -i '' -e "s/NAME_PLACEHOLDER/$NAME/g" -e "s/BASE_PLACEHOLDER/$BASE/g" "$SRC_FILE"
fi

TEST_FILE="$TEST_DIR/${NAME}Tests.swift"
if [ ! -e "$TEST_FILE" ]; then
  cat > "$TEST_FILE" <<'EOF'
import XCTest

@testable import NAME_PLACEHOLDER

final class NAME_PLACEHOLDERTests: XCTestCase {
  func testPlaceholder() {
    // Replace with exhaustive tests: state transitions, effects, action
    // feedback (Constitution V).
    XCTAssertTrue(true)
  }
}
EOF
  sed -i '' "s/NAME_PLACEHOLDER/$NAME/g" "$TEST_FILE"
fi

echo "Created $SRC_DIR/ and $TEST_DIR/."
echo
echo "Register in Package.swift under the correct // MARK: group:"
case "$MODE" in
  feature)
    echo "  .target(name: \"$NAME\", dependencies: ["
    echo "    // e.g. \"ApiClient\", \"Styleguide\", \"TcaHelpers\","
    echo "    // .product(name: \"ComposableArchitecture\", package: \"swift-composable-architecture\"),"
    echo "  ]),"
    echo "  .product(name: \"$NAME\", targets: [\"$NAME\"]),"
    ;;
  client)
    echo "  .target(name: \"$NAME\", dependencies: ["
    echo "    // e.g. \"SharedModels\","
    echo "    // .product(name: \"Dependencies\", package: \"swift-dependencies\"),"
    echo "  ]),"
    echo "  .product(name: \"$NAME\", targets: [\"$NAME\"]),"
    ;;
  live)
    echo "  .target(name: \"$NAME\", dependencies: [ \"NAME_OF_THE_CLIENT_IT_IMPLEMENTS\" ]),"
    echo "  .product(name: \"$NAME\", targets: [\"$NAME\"]),"
    ;;
  plain)
    echo "  .target(name: \"$NAME\", dependencies: []),"
    echo "  .product(name: \"$NAME\", targets: [\"$NAME\"]),"
    ;;
esac
echo "  .testTarget("
echo "    name: \"${NAME}Tests\","
echo "    dependencies: [ \"$NAME\", \"TestHelpers\" ],"
echo "    exclude: [ \"__Snapshots__\" ]"
echo "  ),"
echo
echo "Reminder: *Live modules must be linked ONLY by the app target (Constitution III)."
