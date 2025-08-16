class OntologyAnalysis < ApplicationRecord
  belongs_to :job_analysis
  belongs_to :user_profile
end
