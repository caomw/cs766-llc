% algorithm 4.1 from 

function [final_dictionary] = code_opt_alg_41(B, X, lambda, sigma)
    [M,D] = size(B); % M = codebook size, D = feature size
    [N,D1] = size(B); % N = num examples

    % check dimensions match
    if(D ~= D1)
        error('Dim Mismatch', 'B should be M x D, X should be N x D');
    end
    
    final_dictionary = B;
    for i = 1:N
        d = zeros(M,1);
        
        %locality constraint parameter
        for j = 1:M
            d(j) = exp( norm(X(i,:) - B(j,:)) / sigma) .^ -1;
        end
        d = mat2gray(d); %normalize between 0 and 1
        
        % coding ( size(c) = [1, D] )
        c(i,:) = %argmin(c) norm( X(i,:) - ( c * final_dictionary *  ) ) .^ 2
        
        % remove bias
        
        
        % update basis
    end
end