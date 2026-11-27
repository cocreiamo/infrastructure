/* Requirements of the Cocreiamo infrastructure repository.
 *
 * Conventions
 * - A requirement states what the system must do. It never names a product.
 * - A product is a part; its doc says which product fills the role today.
 * - Each verification is named exactly like the automated test that will
 *   implement it: test_<requirement id>_<what it checks>.
 * - No test is written yet: the model records what must hold, and the
 *   decisions behind it are in docs/adr/.
 */
package Infrastructure {

    // ---- Structure -------------------------------------------------------

    part def System;
    part def Repository;
    part def Pipeline;
    part def StateStore;
    part def KeyService;
    part def SecretFiles;
    part def IdentityFederation;
    part def Toolchain;

    // A platform whose resources the repository describes and changes.
    abstract part def ManagedPlatform;
    part def CloudPlatform :> ManagedPlatform;
    part def CodeHostingPlatform :> ManagedPlatform;
    part def EdgePlatform :> ManagedPlatform;

    part infrastructure : System {
        doc /* The whole: the repository, the pipeline that applies it, what
             * the pipeline needs to run, and the platforms it manages. */

        part repository : Repository {
            doc /* The public git repository cocreiamo/infrastructure on
                 * GitHub, with OpenTofu code composed by Terragrunt
                 * (ADR 0003). */
        }
        part pipeline : Pipeline {
            doc /* GitHub Actions workflows on GitHub-hosted runners, running
                 * Terragrunt and OpenTofu, with no orchestrator
                 * (ADR 0007). */
        }
        part stateStore : StateStore {
            doc /* One private Google Cloud Storage bucket in the European
                 * Union, with object versioning (ADR 0004). */
        }
        part keyService : KeyService {
            doc /* Google Cloud KMS: one key for state and plans, one for the
                 * read-only secrets, one for the secrets that can change
                 * resources (ADR 0004, 0005). */
        }
        part secretFiles : SecretFiles {
            doc /* SOPS files in the repository, read by Terragrunt
                 * (ADR 0005). */
        }
        part identityFederation : IdentityFederation {
            doc /* Workload Identity Federation between GitHub Actions and
                 * Google Cloud, with two service accounts and two GitHub
                 * Environments, plan and apply (ADR 0006). */
        }
        part googleCloud : CloudPlatform {
            doc /* Google Cloud: also hosts the state store, the key service
                 * and the federation. */
        }
        part github : CodeHostingPlatform {
            doc /* The GitHub organization cocreiamo: also hosts the
                 * repository and the pipeline. */
        }
        part cloudflare : EdgePlatform {
            doc /* Cloudflare: zones, records and the other services. */
        }
    }

    part toolchain : Toolchain {
        doc /* mise, OpenTofu, Terragrunt, SOPS, cf-terraforming, tflint,
             * trivy, actionlint, zizmor, gitleaks, REUSE, Renovate, the
             * SysML v2 Pilot Implementation, gaps.toml (ADR 0003). */
    }

    // ---- Day 0: what holds before any resource is managed ----------------

    package Day0 {
        requirement <'R1'> everyDependencyPinned {
            doc /* Every tool, provider, module and pipeline action shall be
                 * referenced by a fixed version together with its checksum
                 * or commit. Floating references such as "latest" shall not
                 * be used. */
            subject tools : Toolchain;
        }
        requirement <'R2'> sameCommandEverywhere {
            doc /* Every check shall be run by the same command on the
                 * maintainer's machine and in the pipeline, with tools
                 * installed only from the versions pinned in the
                 * repository. */
            subject tools : Toolchain;
        }
        requirement <'R3'> everyFileLicensed {
            doc /* Every file in the repository shall carry copyright and
                 * licence information. */
            subject tools : Toolchain;
        }
        requirement <'R4'> everyRequirementVerified {
            doc /* Every requirement in this model shall have at least one
                 * verification, and every verification shall be an automated
                 * test executed by the pipeline. */
            subject tools : Toolchain;
        }
        requirement <'R5'> everyGapRegistered {
            doc /* Every known gap of an adopted component shall be recorded
                 * in one register, and every workaround in the repository
                 * shall name its entry. */
            subject tools : Toolchain;
        }
        requirement <'R6'> generatedFilesCurrent {
            doc /* Every file that can be derived from another file shall be
                 * generated, and a check shall fail when a generated file is
                 * out of date. */
            subject tools : Toolchain;
        }
        requirement <'R7'> bootstrapRepeatable {
            doc /* Everything the pipeline needs in order to run shall be
                 * described in the repository and created by one documented
                 * procedure. Running that procedure again on a system that
                 * is already bootstrapped shall change nothing. */
            subject sys : System;
        }
        requirement <'R8'> bootstrapStateKeptLikeAnyOther {
            doc /* After the bootstrap, the state of the bootstrap shall be
                 * kept in the state store like the state of any other
                 * unit. */
            subject sys : System;
        }
        requirement <'R9'> spendingReported {
            doc /* The maintainer and a second contact shall be notified when
                 * the spending of the platform that hosts the state store
                 * and the key service passes a declared threshold. */
            subject sys : System;
        }
    }

    // ---- Protection: what holds at every moment --------------------------

    package Protection {
        requirement <'R10'> stateNeverStoredInClear {
            doc /* State files and saved plan files shall be encrypted before
                 * they leave the machine that produces them. The state store
                 * and the pipeline's artifacts shall never hold them in
                 * clear. */
            subject sys : System;
        }
        requirement <'R11'> stateStoreNotPublic {
            doc /* The state store shall refuse every request that is not
                 * authenticated and authorized, and it shall not be possible
                 * to make any of its content public. */
            subject store : StateStore;
        }
        requirement <'R12'> stateStoreAndKeysNotRemovable {
            doc /* A change applied by the pipeline shall not be able to
                 * remove the state store, a key of the key service or the
                 * project that holds them. */
            subject sys : System;
        }
        requirement <'R13'> noSecretInClearInRepository {
            doc /* Every secret kept in the repository shall be encrypted
                 * with a key of the key service. No secret shall appear in
                 * clear in any file or in the history. */
            subject repo : Repository;
        }
        requirement <'R14'> noKeyMaterialOutsideKeyService {
            doc /* No encryption key and no passphrase shall exist as a file,
                 * a stored secret or a copy outside the key service. Access
                 * to a key shall be granted and removed only through the
                 * permissions of the key service. */
            subject keys : KeyService;
        }
        requirement <'R15'> noStoredCredentialForFederatedPlatform {
            doc /* The pipeline shall authenticate to the platform that hosts
                 * the state store and the key service with short-lived
                 * federated credentials. No long-lived credential for that
                 * platform shall be stored anywhere. */
            subject federation : IdentityFederation;
        }
        requirement <'R16'> readAndWriteCredentialsSeparated {
            doc /* Credentials that can change resources shall be decryptable
                 * only by the identity that applies from the main branch.
                 * The identity used for a pull request shall be able to read
                 * resources and state, and nothing more. */
            subject federation : IdentityFederation;

            requirement <'R16.1'> pullRequestCannotDecryptWriteSecrets {
                doc /* A job run for a pull request shall be refused when it
                     * asks the key service to decrypt the secrets that can
                     * change resources. */
            }
            requirement <'R16.2'> pullRequestCannotWriteState {
                doc /* A job run for a pull request shall be refused when it
                     * writes to the state store. */
            }
        }
        requirement <'R17'> applyOnlyFromMainAfterApproval {
            doc /* A change shall be applied only from the main branch and
                 * only after the maintainer has explicitly approved that
                 * run. */
            subject pipe : Pipeline;
        }
        requirement <'R18'> outsideChangeGetsNoCredential {
            doc /* A pull request from outside the repository shall obtain no
                 * credential, no secret and no federated token, and a
                 * comment shall never start a job that holds one. */
            subject pipe : Pipeline;
        }
        requirement <'R19'> noResourceValueInPublic {
            doc /* The public outputs of the pipeline (comments, logs, job
                 * summaries, issues) shall show at most the addresses of the
                 * resources and the action planned for each. They shall
                 * never show the value of an attribute of a resource. */
            subject pipe : Pipeline;
        }
        requirement <'R20'> mainBranchProtected {
            doc /* The main branch shall change only through a pull request
                 * whose checks pass. Its history shall not be rewritten or
                 * deleted, and every commit on it shall be signed. */
            subject repo : Repository;
        }
        requirement <'R21'> pipelineLeastPrivilege {
            doc /* Every job of the pipeline shall declare the least
                 * permissions it needs, shall pin every action it uses by
                 * commit, and shall pass no untrusted input to a shell. */
            subject pipe : Pipeline;
        }
        requirement <'R34'> noClientNameInClear {
            doc /* A client shall be named in the repository only by a
                 * generated codename. Its real name, its domain and the
                 * identifiers of its resources shall appear only encrypted,
                 * and no data about a person shall be kept in the repository
                 * at all. */
            subject repo : Repository;
        }
    }

    // ---- Day 1: existing resources come under code -----------------------

    package Day1 {
        requirement <'R22'> adoptionLeavesNoDifference {
            doc /* When a platform has been adopted, a plan of every unit
                 * that describes it shall report no difference. */
            subject sys : System;
        }
        requirement <'R23'> adoptionDeclaredInCode {
            doc /* Every existing resource shall be adopted by a declaration
                 * in the repository that is reviewed and applied like any
                 * other change, not by a command run by hand against the
                 * state. */
            subject repo : Repository;
        }
        requirement <'R24'> adoptionDestroysNothing {
            doc /* Adopting an existing resource shall neither destroy nor
                 * recreate it. */
            subject sys : System;
        }
    }

    // ---- Day 2: every change, and the years after -------------------------

    package Day2 {
        requirement <'R25'> everyChangePlanned {
            doc /* Every pull request from a branch of the repository shall
                 * receive a plan of the units it affects and a public
                 * summary of that plan. */
            subject pipe : Pipeline;
        }
        requirement <'R26'> appliedPlanIsApprovedPlan {
            doc /* The plan that is applied shall be the saved plan the
                 * maintainer approved, not a plan made again after the
                 * approval. */
            subject pipe : Pipeline;
        }
        requirement <'R27'> planDetailReadableByMaintainer {
            doc /* The maintainer shall be able to read the full detail of
                 * any saved plan with one command, using only their own
                 * sign-in. */
            subject pipe : Pipeline;
        }
        requirement <'R28'> noOverlappingApply {
            doc /* Two applies that touch the same unit shall never run at
                 * the same time. */
            subject pipe : Pipeline;
        }
        requirement <'R29'> driftReported {
            doc /* At least once a day every unit shall be compared with the
                 * real resources, and a difference shall be reported to the
                 * maintainer without showing any value of a resource. */
            subject pipe : Pipeline;
        }
        requirement <'R30'> updatesProposed {
            doc /* A new version of any pinned tool, provider, module or
                 * action shall be proposed as a pull request, and shall never
                 * be applied without the maintainer's approval. */
            subject tools : Toolchain;
        }
        requirement <'R31'> earlierStateRestorable {
            doc /* Any version of a state file written in the last 90 days
                 * shall be restorable by a documented procedure. */
            subject store : StateStore;
        }
        requirement <'R32'> proceduresWritten {
            doc /* The repository shall hold a written procedure for the
                 * bootstrap, for adding or replacing a secret, for restoring
                 * a state and for answering a leaked credential. */
            subject repo : Repository;
        }
        requirement <'R33'> expiredCredentialFailsClearly {
            doc /* When a stored credential of a managed platform is no
                 * longer valid, the pipeline shall fail before planning and
                 * shall say which credential is not valid, without showing
                 * it. */
            subject pipe : Pipeline;
        }
        requirement <'R35'> nothingByHandUndeclared {
            doc /* Everything configured by hand on a managed platform shall
                 * be declared in one register in the repository, with the
                 * reason why it is not described as code. */
            subject repo : Repository;
        }
        requirement <'R36'> deadlinesWatched {
            doc /* Every deadline that no platform reminds of (a renewal, an
                 * expiry) shall be declared in one register, and the
                 * maintainer shall be told at least 30 days before each. */
            subject pipe : Pipeline;
        }
        requirement <'R37'> credentialsRotate {
            doc /* Every stored credential shall declare how often it is
                 * replaced, or why it never is, and a credential older than
                 * its declared interval shall be reported to the
                 * maintainer. */
            subject pipe : Pipeline;
        }
        requirement <'R38'> watchedDomainsMatchOwnedDomains {
            doc /* The domains whose expiry is watched shall be exactly the
                 * domains the repository declares as owned. */
            subject repo : Repository;
        }
    }

    // ---- Verifications: one automated test each, not written yet ---------

    package Verification {
        verification def test_R1_every_dependency_pinned {
            subject tools : Toolchain;
            objective { verify Day0::everyDependencyPinned; }
        }
        verification def test_R2_same_command_everywhere {
            subject tools : Toolchain;
            objective { verify Day0::sameCommandEverywhere; }
        }
        verification def test_R3_every_file_licensed {
            subject tools : Toolchain;
            objective { verify Day0::everyFileLicensed; }
        }
        verification def test_R4_every_requirement_verified {
            subject tools : Toolchain;
            objective { verify Day0::everyRequirementVerified; }
        }
        verification def test_R5_every_gap_registered {
            subject tools : Toolchain;
            objective { verify Day0::everyGapRegistered; }
        }
        verification def test_R6_generated_files_current {
            subject tools : Toolchain;
            objective { verify Day0::generatedFilesCurrent; }
        }
        verification def test_R7_bootstrap_repeatable {
            subject sys : System;
            objective { verify Day0::bootstrapRepeatable; }
        }
        verification def test_R8_bootstrap_state_kept_like_any_other {
            subject sys : System;
            objective { verify Day0::bootstrapStateKeptLikeAnyOther; }
        }
        verification def test_R9_spending_reported {
            subject sys : System;
            objective { verify Day0::spendingReported; }
        }
        verification def test_R10_state_never_stored_in_clear {
            subject sys : System;
            objective { verify Protection::stateNeverStoredInClear; }
        }
        verification def test_R11_state_store_not_public {
            subject sys : System;
            objective { verify Protection::stateStoreNotPublic; }
        }
        verification def test_R12_state_store_and_keys_not_removable {
            subject sys : System;
            objective { verify Protection::stateStoreAndKeysNotRemovable; }
        }
        verification def test_R13_no_secret_in_clear_in_repository {
            subject sys : System;
            objective { verify Protection::noSecretInClearInRepository; }
        }
        verification def test_R14_no_key_material_outside_key_service {
            subject sys : System;
            objective { verify Protection::noKeyMaterialOutsideKeyService; }
        }
        verification def test_R15_no_stored_credential_for_federated_platform {
            subject sys : System;
            objective { verify Protection::noStoredCredentialForFederatedPlatform; }
        }
        verification def test_R16_1_pull_request_cannot_decrypt_write_secrets {
            subject sys : System;
            objective { verify Protection::readAndWriteCredentialsSeparated.pullRequestCannotDecryptWriteSecrets; }
        }
        verification def test_R16_2_pull_request_cannot_write_state {
            subject sys : System;
            objective { verify Protection::readAndWriteCredentialsSeparated.pullRequestCannotWriteState; }
        }
        verification def test_R17_apply_only_from_main_after_approval {
            subject sys : System;
            objective { verify Protection::applyOnlyFromMainAfterApproval; }
        }
        verification def test_R18_outside_change_gets_no_credential {
            subject sys : System;
            objective { verify Protection::outsideChangeGetsNoCredential; }
        }
        verification def test_R19_no_resource_value_in_public {
            subject sys : System;
            objective { verify Protection::noResourceValueInPublic; }
        }
        verification def test_R20_main_branch_protected {
            subject sys : System;
            objective { verify Protection::mainBranchProtected; }
        }
        verification def test_R21_pipeline_least_privilege {
            subject sys : System;
            objective { verify Protection::pipelineLeastPrivilege; }
        }
        verification def test_R22_adoption_leaves_no_difference {
            subject sys : System;
            objective { verify Day1::adoptionLeavesNoDifference; }
        }
        verification def test_R23_adoption_declared_in_code {
            subject sys : System;
            objective { verify Day1::adoptionDeclaredInCode; }
        }
        verification def test_R24_adoption_destroys_nothing {
            subject sys : System;
            objective { verify Day1::adoptionDestroysNothing; }
        }
        verification def test_R25_every_change_planned {
            subject sys : System;
            objective { verify Day2::everyChangePlanned; }
        }
        verification def test_R26_applied_plan_is_approved_plan {
            subject sys : System;
            objective { verify Day2::appliedPlanIsApprovedPlan; }
        }
        verification def test_R27_plan_detail_readable_by_maintainer {
            subject sys : System;
            objective { verify Day2::planDetailReadableByMaintainer; }
        }
        verification def test_R28_no_overlapping_apply {
            subject sys : System;
            objective { verify Day2::noOverlappingApply; }
        }
        verification def test_R29_drift_reported {
            subject sys : System;
            objective { verify Day2::driftReported; }
        }
        verification def test_R30_updates_proposed {
            subject tools : Toolchain;
            objective { verify Day2::updatesProposed; }
        }
        verification def test_R31_earlier_state_restorable {
            subject sys : System;
            objective { verify Day2::earlierStateRestorable; }
        }
        verification def test_R32_procedures_written {
            subject sys : System;
            objective { verify Day2::proceduresWritten; }
        }
        verification def test_R33_expired_credential_fails_clearly {
            subject sys : System;
            objective { verify Day2::expiredCredentialFailsClearly; }
        }
        verification def test_R34_no_client_name_in_clear {
            subject sys : System;
            objective { verify Protection::noClientNameInClear; }
        }
        verification def test_R35_nothing_by_hand_undeclared {
            subject sys : System;
            objective { verify Day2::nothingByHandUndeclared; }
        }
        verification def test_R36_deadlines_watched {
            subject sys : System;
            objective { verify Day2::deadlinesWatched; }
        }
        verification def test_R37_credentials_rotate {
            subject sys : System;
            objective { verify Day2::credentialsRotate; }
        }
        verification def test_R38_watched_domains_match_owned_domains {
            subject sys : System;
            objective { verify Day2::watchedDomainsMatchOwnedDomains; }
        }
    }
}
