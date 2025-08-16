class AddRelationsToOntologyAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_reference :ontology_analyses, :job_analysis, null: true, foreign_key: true
    add_reference :ontology_analyses, :user_profile, null: true, foreign_key: true
  end
end
