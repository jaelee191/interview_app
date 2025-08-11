module ApplicationHelper
  def score_color(score)
    return 'text-gray-500' unless score
    
    case score
    when 80..100
      'text-green-600'
    when 60..79
      'text-blue-600'
    when 40..59
      'text-yellow-600'
    else
      'text-red-600'
    end
  end
end
