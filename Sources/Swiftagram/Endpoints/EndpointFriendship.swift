//
//  EndpointFriendship.swift
//  Swiftagram
//
//  Created by Stefano Bertagno on 08/03/2020.
//

import Foundation

import ComposableRequest

public extension Endpoint {
    /// A module-like `enum` holding reference to `friendships` `Endpoint`s. Requires authentication.
    enum Friendship {
        /// The base endpoint.
        private static let base = Endpoint.version1.friendships.appendingDefaultHeader()

        /// A list of users followed by the user matching `identifier`.
        ///
        /// - parameters:
        ///     - identifier: A `String` holding reference to a valid user identifier.
        ///     - query: An optional `String` representing a username or name component to query following. Defaults to `nil`.
        /// - note: This is equal to the user's **following**.
        public static func followed(by identifier: String,
                                    matching query: String? = nil) -> Paginated<Swiftagram.User.Collection,
                                                                                RankedPageReference<String, String>?,
                                                                                Error> {
            .init { secret, session, pages in
                // Persist the rank token.
                let rank = pages.offset?.rank ?? String(Int.random(in: 1_000..<10_000))
                // Prepare the actual pager.
                return Pager(pages.count, offset: pages.offset?.offset) {
                    base.path(appending: identifier)
                        .following
                        .header(appending: secret.header)
                        .header(appending: rank, forKey: "rank_token")
                        .query(appending: ["q": query, "max_id": $0])
                        .publish(with: session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.User.Collection.init)
                        .iterateFirst(stoppingAt: $0)
                }
                .eraseToAnyPublisher()
            }
        }

        /// A list of users following the user matching `identifier`.
        ///
        /// - parameters:
        ///     - identifier: A `String` holding reference to a valid user identifier.
        ///     - query: An optional `String` representing a username or name component to query followers. Defaults to `nil`.
        ///     - page: An optional `String` holding reference to a valid cursor. Defaults to `nil`.
        ///     - rank: An optional `String` making sure users are paginated consistently. Defaults to `secret.client.device.identifier` when `nil`.
        /// - note: This is equal to the user's **followers**.
        public static func following(_ identifier: String,
                                     matching query: String? = nil) -> Paginated<Swiftagram.User.Collection,
                                                                                 RankedPageReference<String, String>?,
                                                                                 Error> {
            .init { secret, session, pages in
                // Persist the rank token.
                let rank = pages.offset?.rank ?? String(Int.random(in: 1_000..<10_000))
                // Prepare the actual pager.
                return Pager(pages.count, offset: pages.offset?.offset) {
                    base.path(appending: identifier)
                        .followers
                        .header(appending: secret.header)
                        .header(appending: rank, forKey: "rank_token")
                        .query(appending: ["q": query, "max_id": $0])
                        .publish(with: session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.User.Collection.init)
                        .iterateFirst(stoppingAt: $0)
                }
                .eraseToAnyPublisher()
            }
        }

        /// The current friendship status between the authenticated user and the one matching `identifier`.
        ///
        /// - parameter identifier: A `String` holding reference to a valid user identifier.
        public static func summary(for identifier: String) -> Disposable<Swiftagram.Friendship, Error> {
            .init { secret, session in
                Deferred {
                    base.show
                        .path(appending: identifier)
                        .header(appending: secret.header)
                        .publish(with: session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.Friendship.init)
                }
                .eraseToAnyPublisher()
            }
        }

        /// The current friendship status between the authenticated user and all users matching `identifiers`.
        ///
        /// - parameter identifiers: A collection of `String`s hoding reference to valid user identifiers.
        public static func summary<C: Collection>(for identifiers: C) -> Disposable<Swiftagram.Friendship.Dictionary, Error>
        where C.Element == String {
            .init { secret, session in
                Deferred {
                    base.path(appending: "show_many/")
                        .header(appending: secret.header)
                        .body(["user_ids": identifiers.joined(separator: ","),
                               "_csrftoken": secret["csrftoken"]!,
                               "_uuid": secret.client.device.identifier.uuidString])
                        .publish(with: session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.Friendship.Dictionary.init)
                }
                .eraseToAnyPublisher()
            }
        }

        /// A list of users who requested to follow you, without having been processed yet.
        public static var pendingRequests: Paginated<Swiftagram.User.Collection, String?, Error> {
            .init { secret, session, pages in
                Pager(pages) {
                    base.pending
                        .header(appending: secret.header)
                        .query(appending: $0, forKey: "max_id")
                        .publish(with: session)
                        .map(\.data)
                        .wrap()
                        .map(Swiftagram.User.Collection.init)
                        .iterateFirst(stoppingAt: $0)
                }
                .eraseToAnyPublisher()
            }
        }
    }
}
