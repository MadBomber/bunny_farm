# Contributing to BunnyFarm

We welcome contributions to BunnyFarm! This guide will help you get started with contributing code, documentation, and other improvements.

## Getting Started

### Prerequisites

- Ruby 2.5 or higher
- RabbitMQ server for testing
- Git for version control
- Bundler for dependency management

### Setting Up Development Environment

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/bunny_farm.git
   cd bunny_farm
   ```

3. **Install dependencies**:
   ```bash
   bundle install
   ```

4. **Set up RabbitMQ** for testing:
   ```bash
   # macOS with Homebrew
   brew install rabbitmq
   brew services start rabbitmq
   
   # Ubuntu/Debian
   sudo apt-get install rabbitmq-server
   sudo systemctl start rabbitmq-server
   ```

5. **Run the tests** to ensure everything works:
   ```bash
   bundle exec rake test
   ```

## Development Philosophy

BunnyFarm follows the **K.I.S.S. (Keep It Simple, Stupid)** design principle:

- **Simplicity over complexity** - Choose simple solutions over elaborate ones
- **Clarity over cleverness** - Write code that's easy to understand
- **Convention over configuration** - Provide sensible defaults
- **Edge cases are not priorities** - Focus on common use cases

## Code Style Guidelines

### Ruby Style

Follow standard Ruby conventions:

```ruby
# Good: Clear, descriptive names
class OrderProcessingMessage < BunnyFarm::Message
  fields :order_id, :customer_email, :items
  actions :validate, :process, :ship
  
  def validate
    validate_order_data
    validate_customer_info
    success! if errors.empty?
  end
end

# Avoid: Unclear or overly clever code
class OPM < BF::Msg
  flds :oid, :ce, :its
  acts :v, :p, :s
  
  def v; vod; vci; suc! if ers.empty?; end
end
```

### Documentation Style

- **Clear examples** - Provide runnable code examples
- **Practical focus** - Show real-world usage patterns  
- **Progressive complexity** - Start simple, build up
- **Consistent format** - Follow established patterns

## Types of Contributions

### 🐛 Bug Fixes

Found a bug? We'd love your help fixing it!

1. **Search existing issues** to avoid duplicates
2. **Create an issue** describing the bug with:
   - Ruby version
   - BunnyFarm version
   - RabbitMQ version
   - Minimal reproduction case
   - Expected vs actual behavior
3. **Submit a pull request** with the fix

### ✨ Feature Additions

Have an idea for a new feature?

1. **Discuss first** - Open an issue to discuss the feature
2. **Keep it simple** - Align with BunnyFarm's philosophy
3. **Consider the common case** - Focus on widely useful features
4. **Include tests** - New features need test coverage
5. **Update documentation** - Include usage examples

### 📚 Documentation Improvements

Documentation improvements are always welcome:

- Fix typos and grammar
- Add missing examples
- Clarify confusing sections
- Create new guides and tutorials
- Update API documentation

### 🧪 Testing Enhancements

Help improve test coverage:

- Add missing test cases
- Improve test reliability
- Add integration tests
- Performance testing
- Cross-platform testing

## Pull Request Process

### Before Submitting

1. **Run the tests**:
   ```bash
   bundle exec rake test
   ```

2. **Check code style**:
   ```bash
   bundle exec rubocop
   ```

3. **Update documentation** if needed

4. **Add tests** for new functionality

### Submitting Your PR

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** with clear, atomic commits:
   ```bash
   git commit -m "Add message retry functionality"
   ```

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a pull request** with:
   - Clear title describing the change
   - Detailed description of what was changed and why
   - Link to related issues
   - Screenshots/examples if applicable

### PR Review Process

1. **Automated checks** run (tests, style, etc.)
2. **Maintainer review** - We'll provide feedback
3. **Address feedback** - Make requested changes
4. **Final review** - Maintainer approval
5. **Merge** - Your contribution is included!

## Testing Guidelines

### Writing Tests

BunnyFarm uses Minitest for testing. Follow these patterns:

```ruby
# test/test_your_feature.rb
require 'minitest_helper'

class TestYourFeature < Minitest::Test
  def setup
    @message = TestMessage.new
  end
  
  def test_basic_functionality
    @message[:field] = 'value'
    @message.your_action
    
    assert @message.successful?
  end
  
  def test_error_handling
    @message[:field] = nil # Invalid value
    @message.your_action
    
    assert @message.failed?
    assert_includes @message.errors, 'Field is required'
  end
end
```

### Test Organization

- **Unit tests** - Test individual methods and classes
- **Integration tests** - Test end-to-end message flows
- **Performance tests** - Verify performance characteristics
- **Edge case tests** - Test boundary conditions

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/test_message.rb

# Run specific test method
bundle exec ruby test/test_message.rb -n test_basic_functionality
```

## Issue Reporting

### Bug Reports

When reporting bugs, include:

```markdown
**Bug Description**
Clear description of the bug

**Environment**
- Ruby version: X.X.X
- BunnyFarm version: X.X.X
- RabbitMQ version: X.X.X
- OS: macOS/Linux/Windows

**Reproduction Steps**
1. Step one
2. Step two
3. Bug occurs

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Minimal Code Example**
```ruby
# Code that reproduces the bug
```

### Feature Requests

For feature requests, provide:

- **Use case** - What problem does this solve?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you consider?
- **Examples** - Show how it would be used

## Code Review Guidelines

### For Contributors

- **Keep PRs focused** - One feature/fix per PR
- **Write clear commit messages** - Explain what and why
- **Be responsive** - Address feedback promptly
- **Test thoroughly** - Ensure changes work correctly

### For Reviewers

- **Be constructive** - Provide helpful feedback
- **Focus on the code** - Not the person
- **Explain reasoning** - Help contributors learn
- **Recognize good work** - Acknowledge quality contributions

## Release Process

BunnyFarm follows semantic versioning:

- **Major version** (X.0.0) - Breaking changes
- **Minor version** (0.X.0) - New features, backwards compatible
- **Patch version** (0.0.X) - Bug fixes, backwards compatible

### Release Criteria

- All tests passing
- Documentation updated
- CHANGELOG.md updated
- Version number updated

## Community Guidelines

### Be Respectful

- **Inclusive environment** - Welcome contributors of all backgrounds
- **Professional communication** - Keep discussions constructive
- **Patient teaching** - Help newcomers learn

### Be Helpful

- **Answer questions** - Help other users and contributors
- **Share knowledge** - Contribute to discussions
- **Mentor newcomers** - Guide new contributors

## Getting Help

Need help contributing? Reach out:

- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and general discussion
- **Pull Request Comments** - For specific code feedback

## Recognition

Contributors are recognized in:

- **CHANGELOG.md** - For significant contributions
- **README.md** - In the contributors section
- **Release notes** - For notable features and fixes

## Next Steps

Ready to contribute?

1. **Browse open issues** - Find something to work on
2. **Join discussions** - Participate in the community
3. **Start small** - Begin with documentation or small bug fixes
4. **Ask questions** - Don't hesitate to ask for help

Thank you for contributing to BunnyFarm! 🐰