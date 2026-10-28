# REFLECTION — GoodCorner (iOS)

## 1. Contexte et périmètre

- **Application** : petite app de petites annonces (test technique leboncoin) qui consomme un serveur local (`http://127.0.0.1:8081`, routes `/listings` et `/categories`).
- **Environnement** : macOS 12.7, Xcode 14.2, Swift 5.7.2, SwiftUI, iOS 16 minimum. Aucune dépendance externe.
- **Socle livré** : liste des annonces, filtre par catégorie, écran de détail, états de chargement / erreur / vide, FR/EN, accessibilité, tests unitaires.
- **Bonus retenu** : brouillon local d'annonce avec Core Data (création, persistance, restauration, suppression/réinitialisation, aucun appel backend).
- **Ajouts hors socle** : recherche (`/listings?query=`), splash animé, photo dans le brouillon, thème visuel aux couleurs du logo.

## 2. Arborescence du projet

```
GoodCorner/
├── App/             Point d'entrée @main (affiche RootView)
├── Models/          Types métier, sans dépendance UI
│   ├── Listing.swift            Listing + ListingsResponse (enveloppe de l'API)
│   ├── ListingCategory.swift    Catégorie (id, name)
│   ├── ListingDraft.swift       Brouillon (struct simple, indépendante de Core Data)
│   └── PriceInput.swift         Nettoyage de la saisie du prix
├── Services/        Accès réseau et utilitaires
│   ├── APIClient.swift          Protocole ListingsService + client URLSession
│   ├── APIError.swift           Erreurs localisées
│   ├── AppConfig.swift          URL de base, construction des URLs d'images
│   └── ImageProcessor.swift     Redimensionnement/compression des photos
├── Persistence/     Core Data
│   ├── PersistenceController.swift  Pile Core Data, modèle défini en code
│   ├── DraftEntity.swift            NSManagedObject du brouillon
│   └── DraftStore.swift             Protocole DraftStore + CoreDataDraftStore
├── ViewModels/
│   ├── ListingsViewModel.swift  État de la liste, catégories, recherche
│   └── DraftViewModel.swift     État du formulaire, sauvegarde automatique
├── Views/           SwiftUI
│   ├── RootView, SplashView
│   ├── ListingsView, ListingRow, CategoryFilterView, MessageStateView
│   ├── ListingDetailView, ListingImageView
│   ├── DraftFormView
│   └── Theme.swift              Couleurs et style « carte »
├── Resources/       en.lproj / fr.lproj (Localizable.strings)
└── Assets.xcassets
GoodCornerTests/     Tests unitaires (réseau, view models, Core Data, saisie du prix)
GoodCornerUITests/   Gabarit généré par Xcode (non utilisé)
```

## 3. Architecture : MVVM en couches

```
View (SwiftUI)  →  ViewModel (ObservableObject)  →  ListingsService / DraftStore (protocoles)
                                                          ↓                      ↓
                                                      APIClient            CoreDataDraftStore
```

- Les **vues** ne contiennent aucune logique réseau ni de persistance : elles affichent un état et transmettent les actions.
- Les **view models** portent l'état (`@Published`) et la logique (chargement, filtrage, sauvegarde automatique).
- L'accès aux données passe par des **protocoles** (`ListingsService`, `DraftStore`) : on peut donc tester les view models avec des faux services, sans serveur ni base de données.
- Contrainte Xcode 14.2 / Swift 5.7 : `ObservableObject` / `@StateObject` (pas `@Observable`), XCTest (pas Swift Testing), `Localizable.strings` (pas de String Catalog).

## 4. Choix techniques : liste, catégories, détail

| Sujet | Choix | Pourquoi |
|---|---|---|
| Réseau | `URLSession` + `async/await`, sans bibliothèque | Suffisant pour deux routes GET, moins de dépendances |
| Décodage | `Decodable` avec `CodingKeys` explicites, dates ISO 8601 | Mapping `snake_case` → `camelCase` visible et sûr ; `images_url` optionnel pour gérer les annonces sans image |
| Enveloppe API | `ListingsResponse` (items, total, page, limit, has_more) | La réponse n'est pas un simple tableau ; la pagination reste possible plus tard |
| Fonction générique | `get<T: Decodable>` | Une seule implémentation pour `/listings` et `/categories` ; le type attendu est fixé par l'appelant |
| Chargement | Annonces et catégories en parallèle (`async let`) | Un seul temps d'attente |
| Catégories | Associées aux annonces par `id` ; filtre côté app qui **conserve l'ordre de l'API** | Exigence de l'énoncé ; pas de requête supplémentaire |
| États | Énumération `idle / loading / loaded / failed(message)` ; l'état « vide » est déduit de la liste filtrée | Un seul état possible à la fois, vues simples ; réessai disponible en cas d'erreur |
| Actualisation | `refreshable` sans remplacer la liste par un spinner | La liste reste visible pendant le rechargement |
| Erreurs | `APIError` localisée (réseau, serveur, décodage) ; une requête annulée n'est jamais affichée comme une erreur | Messages compréhensibles en FR/EN |
| Images | `AsyncImage`, vignette `thumb` dans la liste, `small` dans le détail, placeholder en cas d'absence ou d'échec | Pas de cache maison à maintenir |
| Détail | Image en mode « fit » sur fond neutre | Évite le recadrage et l'agrandissement flou (le serveur ne fournit que deux tailles) |
| FR/EN | `Localizable.strings` ; messages d'erreur via `NSLocalizedString` | Compatible Xcode 14.2 |


## 5. Choix techniques : brouillon d'annonce (Core Data)

- **Modèle défini en code** (`NSManagedObjectModel` dans `PersistenceController`) plutôt qu'un `.xcdatamodeld` : relecture et versionnage plus simples, modèle partagé entre le store réel et les stores de test.
- **Un seul brouillon** (le dernier en cours) : `CoreDataDraftStore` met à jour l'entité existante au lieu d'en créer une à chaque sauvegarde.
- **Séparation domaine / persistance** : `ListingDraft` est une struct simple ; `DraftEntity` ne sort jamais de la couche `Persistence`.
- **Sauvegarde automatique** : debounce de 0,5 s après la frappe, plus sauvegarde immédiate à la fermeture du formulaire et au passage en arrière-plan.
- **Restauration** : au lancement, si un brouillon existe, le formulaire se rouvre après le chargement de la liste.
- **Brouillon vide jamais conservé** : si tous les champs sont vidés, la copie persistée est supprimée.
- **Réinitialiser / Supprimer** : « Réinitialiser » vide le formulaire et reste ouvert ; « Supprimer le brouillon » demande confirmation, supprime et ferme. Dans les deux cas, la copie persistée est effacée.
- **Photo** : choisie avec `PhotosPicker` (pas d'autorisation à demander), réduite à 1280 px et recompressée en JPEG avant stockage, en binaire externe Core Data.
- **Prix** : `PriceInput.sanitize` ne garde que les chiffres et un séparateur décimal (2 décimales max), car `decimalPad` seul n'empêche pas le texte collé ou un clavier physique.

## 6. Tests

- **Réseau** : décodage JSON (enveloppe, image absente, dates), construction des requêtes, encodage du terme de recherche, distinction annulation / panne, via un `URLProtocol` factice (aucun serveur requis).
- **ViewModels** : chargement, ordre conservé, filtre par catégorie, erreur, recherche (debounce, annulation, résultat périmé ignoré).
- **Core Data** : aller-retour, un seul brouillon, suppression, photo, et un test qui relit le fichier SQLite dans un second conteneur pour simuler une relance.
- **Saisie du prix** : lettres, séparateurs, limites, chiffres arabes, idempotence.
- Les tests sont déterministes : faux services, store en mémoire, aucun appel réseau réel.

## 7. Outils d'IA

- **Claude (Anthropic)**, via claude.ai

