# Recipe Collection Smart Contract

A Clarity smart contract for storing and managing cooking recipes on the Stacks blockchain with sharing capabilities.

## Overview

This smart contract allows users to create, manage, and share cooking recipes in a decentralized manner. Each recipe includes a dish name, serving size, and sharing permissions.

## Features

- **Add Recipes**: Create new recipes with dish names and serving sizes
- **Update Recipes**: Modify existing recipes (name and servings)
- **Delete Recipes**: Remove recipes from the cookbook
- **Transfer Ownership**: Hand off recipe ownership to another user
- **Share Recipes**: Grant access to specific users
- **View Recipes**: Read recipe information and cookbook statistics

## Constants

- `head-chef`: The contract deployer
- Error codes:
  - `err-chef-only` (u100): Reserved for future use
  - `err-recipe-unavailable` (u101): Recipe not found
  - `err-recipe-collision` (u102): Reserved for future use
  - `err-invalid-dish-name` (u103): Invalid dish name
  - `err-invalid-servings` (u104): Invalid serving count
  - `err-forbidden` (u105): Unauthorized action

## Data Structure

Each recipe contains:
- `chef`: Owner's principal address
- `dish-name`: Recipe name (1-64 ASCII characters)
- `servings`: Number of servings (1-999,999,999)
- `published-at`: Block height when created
- `sharing-policy`: Access permissions for a specific user

## Public Functions

### `add-recipe`
```clarity
(add-recipe (dish-name (string-ascii 64)) (servings uint))
```
Creates a new recipe and returns its ID.

**Validations:**
- Dish name must be 1-64 characters
- Servings must be between 1 and 999,999,999

### `revise-recipe`
```clarity
(revise-recipe (recipe-id uint) (updated-dish-name (string-ascii 64)) (updated-servings uint))
```
Updates an existing recipe. Only the recipe owner can revise.

### `remove-recipe`
```clarity
(remove-recipe (recipe-id uint))
```
Deletes a recipe from the cookbook. Only the recipe owner can remove.

### `handoff-recipe`
```clarity
(handoff-recipe (recipe-id uint) (new-chef principal))
```
Transfers recipe ownership to another principal.

### `share-recipe` / `unshare-recipe`
```clarity
(share-recipe (recipe-id uint) (can-access bool) (cook principal))
(unshare-recipe (recipe-id uint) (can-access bool) (cook principal))
```
Manages recipe access for specific users. Both functions currently have identical implementation.

## Read-Only Functions

### `get-cookbook-size`
```clarity
(get-cookbook-size)
```
Returns the total number of recipes created.

### `get-recipe-info`
```clarity
(get-recipe-info (recipe-id uint))
```
Retrieves complete information about a specific recipe.

## Usage Example

```clarity
;; Add a new recipe
(contract-call? .recipe-collection add-recipe "Chocolate Chip Cookies" u24)
;; Returns: (ok u1)

;; Update the recipe
(contract-call? .recipe-collection revise-recipe u1 "Double Chocolate Chip Cookies" u36)
;; Returns: (ok true)

;; Get recipe details
(contract-call? .recipe-collection get-recipe-info u1)
;; Returns recipe data

;; Share with another user
(contract-call? .recipe-collection share-recipe u1 true 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Returns: (ok true)

;; Transfer ownership
(contract-call? .recipe-collection handoff-recipe u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;; Returns: (ok true)
```

## Security Considerations

- All write operations verify recipe ownership
- Input validation prevents invalid data entry
- Recipe existence is checked before operations
