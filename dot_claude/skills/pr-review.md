# Pull Request Review for the Current Project

Reads the Pull Request from the current branch in the current project, compares the diff against main, and reviews it from several perspectives.

## Tech Stack Detection

First, detect the project's tech stack:

```bash
# Detect tech stack
BACKEND_STACK=""
FRONTEND_STACK=""

# Detect backend technology
if [ -f "Gemfile" ]; then
  BACKEND_STACK="Ruby on Rails"
elif [ -f "go.mod" ]; then
  BACKEND_STACK="Go"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  BACKEND_STACK="Python"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  BACKEND_STACK="Java"
fi

# Detect frontend technology
if [ -f "package.json" ]; then
  if grep -q "\"react\"" package.json; then
    FRONTEND_STACK="React"
  elif grep -q "\"vue\"" package.json; then
    FRONTEND_STACK="Vue"
  elif grep -q "\"@angular/core\"" package.json; then
    FRONTEND_STACK="Angular"
  elif grep -q "\"next\"" package.json; then
    FRONTEND_STACK="Next.js"
  elif grep -q "\"nuxt\"" package.json; then
    FRONTEND_STACK="Nuxt"
  else
    FRONTEND_STACK="Node.js"
  fi
fi

# Display detection results
echo "Detected tech stack:"
[ -n "$BACKEND_STACK" ] && echo "- Backend: $BACKEND_STACK"
[ -n "$FRONTEND_STACK" ] && echo "- Frontend: $FRONTEND_STACK"

# If no tech stack was detected
if [ -z "$BACKEND_STACK" ] && [ -z "$FRONTEND_STACK" ]; then
  echo "- Could not determine the tech stack. Reviewing from a general perspective."
fi

# If multiple tech stacks are detected, ask the user
REVIEW_SCOPE="both"
if [ -n "$BACKEND_STACK" ] && [ -n "$FRONTEND_STACK" ]; then
  echo ""
  echo "This project uses multiple tech stacks."
  echo "Which perspective would you like to review from?"
  echo "(1) Review from both perspectives"
  echo "(2) Backend perspective only"
  echo "(3) Frontend perspective only"
  read -p "Choice (1-3): " REVIEW_CHOICE

  case $REVIEW_CHOICE in
    2) REVIEW_SCOPE="backend" ;;
    3) REVIEW_SCOPE="frontend" ;;
    *) REVIEW_SCOPE="both" ;;
  esac
fi
```

## Pull Request Review

Load the Pull Request description by running:

```bash
gh pr view
```

## Review Perspectives

There are three severity levels for review findings: Critical, Warning, and Info. Determine the level based on the nature of the finding.

### Common Perspectives (All Projects)

#### 1. Code Quality (Info/Warning)
- **Single Responsibility Principle**: Are classes and methods focused on a single responsibility?
- **Duplicate Code**: Is the DRY principle being followed?
- **YAGNI**: Is the design over-engineered with unnecessary abstractions or premature optimizations?
- **Defensive Design**: Is the interface kept as narrow as needed? Is the design structured to prevent misuse?

#### 2. Harmony with the Project (Warning)
- **Conventions**: If the project has documents containing conventions, does the code comply with them?
- **Harmony**: Does the code harmonize and cooperate with the existing design and code of the project?
- **Deviation**: Does the code deviate from the existing structure of the project? Does it impose unnecessary cognitive load on teammates?

#### 3. Error Handling (Warning)
- **Exception Handling**: Are there any uncaught exceptions or missing error handling?
- **Validation**: Are appropriate validation rules in place for save operations?

#### 4. Testing (Info)
- **Test Presence**: Are tests added appropriately—neither too few nor too many—for new features and bug fixes?
- **Test Coverage**: Are critical paths covered? Are unnecessary test cases avoided?
- **Test Quality**: Are assertions too coarse-grained? Are they appropriate and proportionate to the test cases?

#### 5. General Security (Critical/Warning)
- **Sensitive Information Exposure**: Are passwords, API keys, or tokens hardcoded?
- **Log Output**: Is sensitive information logged in production environments?
- **Environment Variables**: Are there hardcoded environment-specific settings?
- **Dependency Vulnerabilities**: Are any dependencies with known security alerts being used?

#### 6. Other (Info/Warning)
- **Backward Compatibility**: Are there any breaking changes to existing APIs?

### Backend-Specific Perspectives

This section applies when `REVIEW_SCOPE` is "backend" or "both".

#### 1. Security (Critical)
- **SQL Injection**: Is user input being passed directly into SQL queries?
- **Authentication & Authorization**: Are unauthorized actions being executed?

#### 2. Performance (Warning)
- **N+1 Queries**: Are there missing Eager Loading or potential N+1 query occurrences?
- **Unnecessary Queries**: Are there DB accesses inside loops?
- **Indexes**: Are indexes considered for columns used in search conditions?
- **Caching**: Is in-memory caching considered for frequently accessed data?

#### 3. API Design (Info/Warning)
- **RESTful Design**: Does the API conform to REST principles?
- **Endpoint Naming**: Are consistent naming conventions used?

### Frontend-Specific Perspectives

This section applies when `REVIEW_SCOPE` is "frontend" or "both".

#### 1. Security (Critical)
- **XSS**: Is there unescaped user input or output?
  - React: Inappropriate use of `dangerouslySetInnerHTML`
  - Angular: Use of `innerHTML` without `DomSanitizer`
  - Vue: Inappropriate use of `v-html`

#### 2. Performance (Warning)
- **Re-render Optimization**: Are there unnecessary re-renders?
  - React: Appropriate use of `useMemo`, `useCallback`, `React.memo`
  - Angular: Leveraging `OnPush` Change Detection strategy
  - Vue: Appropriate use of `computed` properties
- **Bundle Size**: Is lazy loading and tree-shaking considered?
- **Large Lists**: Is virtual scrolling considered for displaying large amounts of data?

#### 3. Memory Management (Warning)
- **Resource Cleanup**: Are event listeners and Subscriptions being properly released?
  - React: Cleanup functions in `useEffect`
  - Angular: Unsubscribing in `ngOnDestroy`
  - Vue: Cleanup in `onUnmounted`

#### 4. Accessibility (Info)
- **ARIA Attributes**: Are appropriate ARIA attributes set?
- **Keyboard Navigation**: Is the UI fully operable with keyboard only?

## Output

Retrieve the PR number to determine the filename, and output to the repository root of the project:

```bash
# Get the PR number
PR_NUMBER=$(gh pr view --json number -q .number)

# Use a timestamp if the PR number cannot be retrieved
if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(date +%Y%m%d-%H%M%S)
fi

OUTPUT_FILE="pr-review-${PR_NUMBER}.md"
```

### Output Rules

- **Critical**: Display all (no limit)
- **Warning**: Display up to 10, prioritized by severity
- **Info**: Display up to 5, prioritized by severity
- Keep descriptions concise and avoid verbose phrasing
- Write code examples in the language of the detected tech stack

### Output Format

The following is an example of the output format:

```markdown
# Review Summary

- Critical: n item(s) (all displayed)
- Warning: n item(s) (up to 10 displayed)
- Info: n item(s) (up to 5 displayed)

# Review Items

## [Critical]: Query parameter passed directly into WHERE clause

- **Location**: app/controllers/users_controller.rb:12
- **Description**: User input is passed directly as shown below, posing a risk of SQL injection.

```ruby
# Affected code
user = User.where("name = '#{params[:name]}'")
```

```ruby
# Suggested fix
user = User.where(name: params[:name])
```

## [Warning]: Subscription not released

- **Location**: src/app/components/user-list/user-list.component.ts:25
- **Description**: The Subscription is not released in ngOnDestroy, which may cause a memory leak.

```typescript
// Affected code
ngOnInit() {
  this.userService.getUsers().subscribe(users => {
    this.users = users;
  });
}
```

```typescript
// Suggested fix
private subscription: Subscription;

ngOnInit() {
  this.subscription = this.userService.getUsers().subscribe(users => {
    this.users = users;
  });
}

ngOnDestroy() {
  this.subscription?.unsubscribe();
}
```

## [Info]: Insufficient test cases

- **Location**: src/app/services/auth.service.spec.ts
- **Description**: There are no test cases for error handling on login failure.

```typescript
// Test case to add
it('should handle login error', () => {
  // Test to verify behavior on error
});
```
```
