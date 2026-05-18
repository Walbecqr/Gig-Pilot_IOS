import XCTest
@testable import GigPilot

final class OfferScoringEngineTests: XCTestCase {

    // Standard profile: min $5 payout, $1.50/mi, $15/hr, max 3.0 mi
    private func standardProfile() -> FilterProfile {
        FilterProfile(
            name: "Standard",
            minimumPayout: 5.0,
            minimumPayPerMile: 1.5,
            minimumHourlyRate: 15.0,
            maximumPickupDistanceMiles: 3.0,
            isDefault: true
        )
    }

    // Helper to build offer quickly
    private func offer(
        payout:   Double = 8.0,
        distance: Double = 2.0,
        duration: Double = 25.0,
        platform: Platform = .doorDash,
        orderType: OrderType? = .food
    ) -> Offer {
        Offer(
            platform: platform,
            payout:   payout,
            pickupDistanceMiles: distance,
            estimatedDurationMinutes: duration,
            orderType: orderType
        )
    }

    // MARK: – Accept

    func testAcceptWhenAllCriteriaMet() {
        // $8 / 2mi / 25min → $4/mi, $19.2/hr — all above standard thresholds
        let result = OfferScoringEngine.score(offer: offer(), against: standardProfile())
        XCTAssertTrue(result.isAccept, "Expected accept, got: \(result.label) — \(result.reason)")
    }

    // MARK: – Hard Declines

    func testDeclineWhenPayoutBelowMinimum() {
        let result = OfferScoringEngine.score(offer: offer(payout: 4.99), against: standardProfile())
        XCTAssertTrue(result.isDecline)
        XCTAssertTrue(result.reason.contains("minimum"), result.reason)
    }

    func testDeclineWhenDistanceExceedsMaximum() {
        let result = OfferScoringEngine.score(offer: offer(distance: 3.1), against: standardProfile())
        XCTAssertTrue(result.isDecline)
        XCTAssertTrue(result.reason.contains("exceeds"), result.reason)
    }

    func testDeclineWhenBothSoftCriteriaFail() {
        // $6 / 5.0mi (under max) / 60min → $1.20/mi (< $1.50) AND $6/hr (< $15)
        let result = OfferScoringEngine.score(offer: offer(payout: 6.0, distance: 5.0, duration: 60.0), against: standardProfile())
        // Note: distance 5.0 > 3.0 max → hard decline; adjust max for this test
        let lenientProfile = FilterProfile(
            name: "Lenient",
            minimumPayout: 5.0,
            minimumPayPerMile: 1.5,
            minimumHourlyRate: 15.0,
            maximumPickupDistanceMiles: 10.0
        )
        let result2 = OfferScoringEngine.score(offer: offer(payout: 6.0, distance: 5.0, duration: 60.0), against: lenientProfile)
        XCTAssertTrue(result2.isDecline, "Expected decline (both soft criteria fail), got: \(result2.label)")
    }

    // MARK: – Marginal

    func testMarginalWhenOnlyPayPerMileFails() {
        // $6.50 / 5.0mi (lenient max) / 20min → $1.30/mi (< $1.50) but $19.50/hr (OK)
        let profile = FilterProfile(
            name: "Test",
            minimumPayout: 5.0,
            minimumPayPerMile: 1.5,
            minimumHourlyRate: 15.0,
            maximumPickupDistanceMiles: 10.0
        )
        let result = OfferScoringEngine.score(offer: offer(payout: 6.5, distance: 5.0, duration: 20.0), against: profile)
        XCTAssertTrue(result.isMarginal, "Expected marginal (only $/mi fails), got: \(result.label) — \(result.reason)")
    }

    func testMarginalWhenOnlyHourlyRateFails() {
        // $7.50 / 2.0mi / 60min → $3.75/mi (OK) but $7.50/hr (< $15)
        let result = OfferScoringEngine.score(offer: offer(payout: 7.50, distance: 2.0, duration: 60.0), against: standardProfile())
        XCTAssertTrue(result.isMarginal, "Expected marginal (only $/hr fails), got: \(result.label) — \(result.reason)")
    }

    func testMarginalWhenOnlyOrderTypeFails() {
        // Profile accepts only .grocery; offer is .food → one soft failure → .marginal
        // Numeric criteria all pass: $8/2mi/25min → $4/mi (>$1.50), $19.2/hr (>$15)
        let groceryOnly = FilterProfile(
            name: "Grocery Only",
            minimumPayout: 5.0,
            minimumPayPerMile: 1.5,
            minimumHourlyRate: 15.0,
            maximumPickupDistanceMiles: 10.0,
            preferredOrderTypesJSON: "[\"grocery\"]"
        )
        let result = OfferScoringEngine.score(offer: offer(orderType: .food), against: groceryOnly)
        XCTAssertTrue(result.isMarginal, "Expected marginal (only order type fails), got: \(result.label) — \(result.reason)")
    }

    // MARK: – Voice Script

    func testVoiceScriptContainsPayoutForAccept() {
        let o = offer(payout: 8.50, distance: 2.1)
        let result = ScoringResult.accept(reason: "all met")
        let script = OfferScoringEngine.voiceScript(for: result, offer: o)
        XCTAssertTrue(script.contains("DoorDash"), script)
        XCTAssertTrue(script.lowercased().contains("accept"), script)
        XCTAssertTrue(script.contains("8"), script)   // dollars spoken
    }

    func testVoiceScriptForDeclineOmitsDistance() {
        let o = offer(payout: 3.0, distance: 0.5)
        let result = ScoringResult.decline(reason: "payout too low")
        let script = OfferScoringEngine.voiceScript(for: result, offer: o)
        XCTAssertTrue(script.lowercased().contains("decline"), script)
        XCTAssertFalse(script.contains("miles"), "Decline voice script should not mention distance: \(script)")
    }

    // MARK: – Edge Cases

    func testZeroDistanceDoesNotCrash() {
        let o = offer(distance: 0.0)
        let result = OfferScoringEngine.score(offer: o, against: standardProfile())
        XCTAssertNotNil(result)
        // payPerMile guard returns 0 when distance == 0 → fails $/mi soft check → marginal or decline
    }

    func testZeroDurationSkipsHourlyCheck() {
        // When duration is 0 the hourly rate check is skipped entirely
        let o = offer(payout: 8.0, distance: 2.0, duration: 0.0)
        let result = OfferScoringEngine.score(offer: o, against: standardProfile())
        // Only $/mi check applies; $8/2mi = $4/mi > $1.50 → accept (hourly skipped)
        XCTAssertTrue(result.isAccept, "Expected accept when duration is 0 (hourly skipped), got: \(result.label)")
    }
}
