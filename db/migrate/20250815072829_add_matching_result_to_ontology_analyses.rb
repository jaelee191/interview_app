class AddMatchingResultToOntologyAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :ontology_analyses, :matching_result, :jsonb
  end
end
